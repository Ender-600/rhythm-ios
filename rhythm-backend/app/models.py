from typing import Literal

from pydantic import BaseModel, Field


class ExistingTask(BaseModel):
    title: str
    status: str | None = None
    priority: str | None = None
    window_start: str | None = None
    window_end: str | None = None


class ParseRequest(BaseModel):
    utterance: str = Field(min_length=1)
    existing_tasks: list[ExistingTask] = Field(default_factory=list)
    timezone: str = "UTC"


class CreateTask(BaseModel):
    title: str
    schedule_description: str | None = None
    schedule_start: str | None = None
    schedule_end: str | None = None
    deadline: str | None = None
    priority: Literal["urgent", "normal", "low"] = "normal"
    note: str | None = None
    is_flexible: bool = True


class UpdateTask(BaseModel):
    action: Literal[
        "task_started",
        "task_paused",
        "task_resumed",
        "task_completed",
        "task_skipped",
        "task_deleted",
        "task_snoozed",
        "task_rescheduled",
    ]
    target_description: str
    title_keywords: list[str] | None = None
    time_reference: str | None = None
    status_filter: Literal["not_started", "in_progress", "done"] | None = None
    is_multiple: bool = False
    snooze_duration: int | None = None
    snooze_until: str | None = None
    new_schedule_description: str | None = None
    new_schedule_start: str | None = None
    new_schedule_end: str | None = None
    reason: str | None = None


class ParseResponse(BaseModel):
    create_tasks: list[CreateTask] = Field(default_factory=list)
    update_tasks: list[UpdateTask] = Field(default_factory=list)
    confidence: float = Field(ge=0, le=1)
    source: Literal["llm", "backend_fallback"] = "llm"
