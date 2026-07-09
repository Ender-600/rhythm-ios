# rhythm-backend

Backend API for the Rhythm app — planning signal extraction, task sync, and event logging.

## Status

Initial Python LLM backend for the voice quick-add flow.

## Setup

```bash
cd rhythm-backend
uv sync
```

Set LLM provider config:

```bash
cp .env.example .env
```

Then edit `.env` and set `OPENAI_API_KEY`. `uv` creates and manages the local
`.venv` automatically from `pyproject.toml` and `uv.lock`.

The API is OpenAI-compatible. You can point `OPENAI_BASE_URL` and `LLM_MODEL` at another compatible provider.

## Run

```bash
uv run --env-file .env uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

Basic parse check:

```bash
curl -X POST http://localhost:8000/api/v1/parse \
  -H "Content-Type: application/json" \
  -d '{"utterance":"今晚提醒我看书","existing_tasks":[],"timezone":"Asia/Shanghai"}'
```

If `OPENAI_API_KEY` is not set, the backend returns a small deterministic fallback response so the iOS voice-input path can still be tested end to end.

## API

The iOS client expects endpoints such as:

```
POST /api/v1/parse
POST /api/v1/tasks
POST /api/v1/events/batch
```

See [rhythm-ios/README.md](../rhythm-ios/README.md) for full API contract.

### `POST /api/v1/parse`

Request:

```json
{
  "utterance": "今晚提醒我看书",
  "existing_tasks": [
    {
      "title": "回邮件",
      "status": "not_started",
      "priority": "normal",
      "window_start": "2026-07-08T09:00:00Z",
      "window_end": "2026-07-08T10:00:00Z"
    }
  ],
  "timezone": "Asia/Shanghai"
}
```

Response:

```json
{
  "create_tasks": [
    {
      "title": "看书",
      "schedule_description": "tonight",
      "schedule_start": "2026-07-08T19:00:00.000+08:00",
      "schedule_end": "2026-07-08T22:00:00.000+08:00",
      "deadline": null,
      "priority": "normal",
      "note": null,
      "is_flexible": true
    }
  ],
  "update_tasks": [],
  "confidence": 0.8,
  "source": "llm"
}
```
