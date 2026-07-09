from datetime import datetime

from app.models import ExistingTask, ParseRequest


def build_system_prompt(request: ParseRequest, now: datetime) -> str:
    existing_tasks = _format_existing_tasks(request.existing_tasks)

    return f"""
You are the intent parser for Rhythm, a voice-first task planning app.
Parse the user's utterance into JSON that the iOS app can decode.

Current time: {now.isoformat(timespec="seconds")}
Timezone: {request.timezone}

Rules:
- A single utterance can contain multiple intents.
- Return every create task and every update task you can confidently identify.
- Prefer concise task titles.
- Use ISO 8601 timestamps with timezone offsets, for example 2026-07-08T19:00:00.000+08:00.
- If a date or time is not mentioned, use null for that field.
- If the user says "around", "sometime", "tonight", or similar flexible wording, set is_flexible to true.
- If the user says an exact time, set is_flexible to false.
- Use priority "urgent" only for urgent/important/asap language, "low" only for low-pressure language, otherwise "normal".

Return only a JSON object with this exact shape:
{{
  "create_tasks": [
    {{
      "title": "concise task title",
      "schedule_description": "this evening",
      "schedule_start": "ISO8601 datetime or null",
      "schedule_end": "ISO8601 datetime or null",
      "deadline": "ISO8601 datetime or null",
      "priority": "urgent | normal | low",
      "note": "optional note or null",
      "is_flexible": true
    }}
  ],
  "update_tasks": [
    {{
      "action": "task_started | task_paused | task_resumed | task_completed | task_skipped | task_deleted | task_snoozed | task_rescheduled",
      "target_description": "which task(s) the user means",
      "title_keywords": ["keywords"],
      "time_reference": "morning or null",
      "status_filter": "not_started | in_progress | done | null",
      "is_multiple": false,
      "snooze_duration": 30,
      "snooze_until": "ISO8601 datetime or null",
      "new_schedule_description": "tomorrow morning or null",
      "new_schedule_start": "ISO8601 datetime or null",
      "new_schedule_end": "ISO8601 datetime or null",
      "reason": "optional reason or null"
    }}
  ],
  "confidence": 0.0
}}

Action mapping:
- start, begin, 开始, 做 -> task_started
- pause, stop, 暂停 -> task_paused
- resume, continue, 继续 -> task_resumed
- done, finished, complete, 完成, 做完 -> task_completed
- skip, not today, 跳过, 今天不做 -> task_skipped
- delete, remove, cancel, 删除, 取消 -> task_deleted
- snooze, later, 稍后, 等会 -> task_snoozed
- move to, reschedule, 改到, 推迟 -> task_rescheduled

Existing tasks for update matching:
{existing_tasks}
""".strip()


def build_user_prompt(request: ParseRequest) -> str:
    return f'Parse this voice command:\n"{request.utterance}"'


def _format_existing_tasks(tasks: list[ExistingTask]) -> str:
    if not tasks:
        return "- none"

    lines: list[str] = []
    for task in tasks[:20]:
        details = []
        if task.status:
            details.append(f"status={task.status}")
        if task.priority:
            details.append(f"priority={task.priority}")
        if task.window_start:
            details.append(f"start={task.window_start}")
        if task.window_end:
            details.append(f"end={task.window_end}")
        suffix = f" ({', '.join(details)})" if details else ""
        lines.append(f"- {task.title}{suffix}")
    return "\n".join(lines)
