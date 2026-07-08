import json
import os
import re
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

import httpx

from app.models import CreateTask, ParseRequest, ParseResponse, UpdateTask
from app.prompts import build_system_prompt, build_user_prompt


class LLMProviderError(RuntimeError):
    """Raised when the configured LLM provider cannot return a usable response."""


@dataclass(frozen=True)
class LLMSettings:
    api_key: str
    base_url: str
    model: str
    timeout_seconds: float
    max_tokens: int
    temperature: float

    @classmethod
    def from_env(cls) -> "LLMSettings":
        return cls(
            api_key=os.getenv("OPENAI_API_KEY", ""),
            base_url=os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1"),
            model=os.getenv("LLM_MODEL", "gpt-4o-mini"),
            timeout_seconds=float(os.getenv("LLM_TIMEOUT_SECONDS", "30")),
            max_tokens=int(os.getenv("LLM_MAX_TOKENS", "1000")),
            temperature=float(os.getenv("LLM_TEMPERATURE", "0.2")),
        )


class LLMClient:
    def __init__(self, settings: LLMSettings | None = None) -> None:
        self.settings = settings or LLMSettings.from_env()

    @property
    def is_configured(self) -> bool:
        return bool(self.settings.api_key)

    async def parse_utterance(self, request: ParseRequest) -> ParseResponse:
        now = _current_time(request.timezone)

        if not self.is_configured:
            return fallback_parse(request, now)

        payload = self._build_chat_payload(request, now, include_response_format=True)
        try:
            data = await self._post_chat_completion(payload)
        except LLMProviderError as error:
            if "response_format" not in str(error):
                raise
            payload = self._build_chat_payload(request, now, include_response_format=False)
            data = await self._post_chat_completion(payload)

        content = _extract_message_content(data)
        parsed = _parse_json_object(content)
        parsed.setdefault("create_tasks", [])
        parsed.setdefault("update_tasks", [])
        parsed.setdefault("confidence", 0.7)
        parsed["source"] = "llm"
        return ParseResponse(**parsed)

    def _build_chat_payload(
        self,
        request: ParseRequest,
        now: datetime,
        include_response_format: bool,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "model": self.settings.model,
            "messages": [
                {"role": "system", "content": build_system_prompt(request, now)},
                {"role": "user", "content": build_user_prompt(request)},
            ],
            "temperature": self.settings.temperature,
            "max_tokens": self.settings.max_tokens,
        }

        if include_response_format:
            payload["response_format"] = {"type": "json_object"}

        return payload

    async def _post_chat_completion(self, payload: dict[str, Any]) -> dict[str, Any]:
        url = f"{self.settings.base_url.rstrip('/')}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.settings.api_key}",
            "Content-Type": "application/json",
        }

        try:
            async with httpx.AsyncClient(timeout=self.settings.timeout_seconds) as client:
                response = await client.post(url, headers=headers, json=payload)
        except httpx.HTTPError as error:
            raise LLMProviderError(f"LLM provider request failed: {error}") from error

        if response.status_code >= 400:
            raise LLMProviderError(
                f"LLM provider returned {response.status_code}: {response.text[:500]}"
            )

        try:
            return response.json()
        except json.JSONDecodeError as error:
            raise LLMProviderError("LLM provider returned non-JSON response") from error


def fallback_parse(request: ParseRequest, now: datetime | None = None) -> ParseResponse:
    now = now or _current_time(request.timezone)
    create_tasks: list[CreateTask] = []
    update_tasks: list[UpdateTask] = []

    for segment in _split_segments(request.utterance):
        update = _fallback_update(segment, now)
        if update:
            update_tasks.append(update)
            continue

        title = _fallback_title(segment)
        if title:
            schedule_description, schedule_start, schedule_end, is_flexible = _fallback_schedule(
                segment,
                now,
            )
            create_tasks.append(
                CreateTask(
                    title=title,
                    schedule_description=schedule_description,
                    schedule_start=schedule_start,
                    schedule_end=schedule_end,
                    priority=_fallback_priority(segment),
                    is_flexible=is_flexible,
                )
            )

    if not create_tasks and not update_tasks:
        create_tasks.append(
            CreateTask(
                title=_fallback_title(request.utterance) or request.utterance.strip(),
                priority=_fallback_priority(request.utterance),
            )
        )

    return ParseResponse(
        create_tasks=create_tasks,
        update_tasks=update_tasks,
        confidence=0.45,
        source="backend_fallback",
    )


def _current_time(timezone: str) -> datetime:
    try:
        tz = ZoneInfo(timezone)
    except ZoneInfoNotFoundError:
        tz = ZoneInfo("UTC")
    return datetime.now(tz)


def _extract_message_content(data: dict[str, Any]) -> str:
    try:
        return data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as error:
        raise LLMProviderError("LLM provider response is missing message content") from error


def _parse_json_object(content: str) -> dict[str, Any]:
    text = content.strip()

    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.IGNORECASE)
        text = re.sub(r"\s*```$", "", text)

    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise LLMProviderError("LLM message did not include a JSON object")

    try:
        parsed = json.loads(text[start : end + 1])
    except json.JSONDecodeError as error:
        raise LLMProviderError("LLM message included invalid JSON") from error

    if not isinstance(parsed, dict):
        raise LLMProviderError("LLM JSON response must be an object")

    return parsed


def _split_segments(text: str) -> list[str]:
    pattern = r"\s+(?:and|then|also)\s+|[,，]\s*(?:then|and)?\s*|然后|还要|顺便|另外|同时|接着|并且"
    return [
        part.strip()
        for part in re.split(pattern, text, flags=re.IGNORECASE)
        if part.strip()
    ]


def _fallback_update(segment: str, now: datetime) -> UpdateTask | None:
    lowered = segment.lower()
    mappings = [
        (["done", "finished", "complete", "completed", "完成", "做完"], "task_completed"),
        (["pause", "stop", "暂停"], "task_paused"),
        (["resume", "continue", "继续"], "task_resumed"),
        (["skip", "not today", "跳过", "今天不做"], "task_skipped"),
        (["delete", "remove", "cancel", "删除", "取消"], "task_deleted"),
        (["snooze", "later", "remind me later", "稍后", "等会"], "task_snoozed"),
        (["reschedule", "move to", "改到", "推迟"], "task_rescheduled"),
        (["start", "begin", "开始"], "task_started"),
    ]

    for keywords, action in mappings:
        if any(keyword in lowered for keyword in keywords):
            schedule_description, schedule_start, schedule_end, _ = _fallback_schedule(
                segment,
                now,
            )
            return UpdateTask(
                action=action,  # type: ignore[arg-type]
                target_description=segment,
                title_keywords=_fallback_keywords(segment),
                time_reference=_fallback_time_reference(segment),
                is_multiple=_is_multiple_reference(segment),
                snooze_duration=30 if action == "task_snoozed" else None,
                new_schedule_description=(
                    schedule_description if action == "task_rescheduled" else None
                ),
                new_schedule_start=schedule_start if action == "task_rescheduled" else None,
                new_schedule_end=schedule_end if action == "task_rescheduled" else None,
            )

    return None


def _fallback_title(text: str) -> str:
    title = text.strip()
    filler_words = [
        "remind me to",
        "add a task to",
        "add task to",
        "add",
        "please",
        "帮我安排",
        "安排",
        "提醒我",
        "添加一个",
        "添加",
        "新增",
        "我要",
        "要",
    ]
    time_words = [
        "tonight",
        "this evening",
        "tomorrow morning",
        "tomorrow",
        "this afternoon",
        "later",
        "今晚",
        "明天早上",
        "明早",
        "明天",
        "今天下午",
        "下午",
        "稍后",
        "等会",
    ]

    for word in filler_words + time_words:
        title = re.sub(re.escape(word), "", title, flags=re.IGNORECASE)

    title = re.sub(r"\s+", " ", title).strip(" ，,。.!?")
    return title[:60]


def _fallback_schedule(text: str, now: datetime) -> tuple[str | None, str | None, str | None, bool]:
    lowered = text.lower()

    if any(token in lowered for token in ["tonight", "this evening", "今晚", "晚上"]):
        start = _with_time(now, 19)
        end = _with_time(now, 22)
        if end < now:
            start += timedelta(days=1)
            end += timedelta(days=1)
        return "tonight", _to_iso(start), _to_iso(end), True

    if any(token in lowered for token in ["tomorrow morning", "明天早上", "明早"]):
        base = now + timedelta(days=1)
        return "tomorrow morning", _to_iso(_with_time(base, 9)), _to_iso(_with_time(base, 12)), True

    if any(token in lowered for token in ["tomorrow", "明天"]):
        base = now + timedelta(days=1)
        return "tomorrow", _to_iso(_with_time(base, 9)), None, True

    if any(token in lowered for token in ["this afternoon", "afternoon", "今天下午", "下午"]):
        start = _with_time(now, 13)
        end = _with_time(now, 17)
        if end < now:
            start += timedelta(days=1)
            end += timedelta(days=1)
        return "this afternoon", _to_iso(start), _to_iso(end), True

    if any(token in lowered for token in ["later", "soon", "稍后", "等会"]):
        return "later", _to_iso(now + timedelta(hours=1)), None, True

    return None, None, None, True


def _fallback_priority(text: str) -> str:
    lowered = text.lower()
    if any(token in lowered for token in ["urgent", "important", "asap", "紧急", "重要"]):
        return "urgent"
    if any(token in lowered for token in ["whenever", "low priority", "maybe", "有空", "不急"]):
        return "low"
    return "normal"


def _fallback_keywords(text: str) -> list[str]:
    stop_words = {
        "the",
        "a",
        "an",
        "to",
        "for",
        "my",
        "this",
        "that",
        "with",
        "and",
        "or",
        "is",
        "it",
        "start",
        "done",
        "complete",
        "delete",
        "remove",
    }
    tokens = re.findall(r"[A-Za-z0-9]+|[\u4e00-\u9fff]+", text.lower())
    keywords = [token for token in tokens if len(token) > 1 and token not in stop_words]
    return keywords[:5]


def _fallback_time_reference(text: str) -> str | None:
    lowered = text.lower()
    if any(token in lowered for token in ["morning", "早上", "上午"]):
        return "morning"
    if any(token in lowered for token in ["afternoon", "下午"]):
        return "afternoon"
    if any(token in lowered for token in ["evening", "tonight", "晚上", "今晚"]):
        return "evening"
    return None


def _is_multiple_reference(text: str) -> bool:
    lowered = text.lower()
    return any(token in lowered for token in ["all", "everything", "全部", "所有", "都"])


def _with_time(value: datetime, hour: int, minute: int = 0) -> datetime:
    return value.replace(hour=hour, minute=minute, second=0, microsecond=0)


def _to_iso(value: datetime) -> str:
    return value.isoformat(timespec="milliseconds")
