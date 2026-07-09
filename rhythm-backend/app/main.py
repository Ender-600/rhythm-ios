import os

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.llm_client import LLMClient, LLMProviderError
from app.models import ParseRequest, ParseResponse


def create_app() -> FastAPI:
    app = FastAPI(
        title="Rhythm Backend",
        description="Backend API for Rhythm voice parsing and LLM calls.",
        version="0.1.0",
    )

    cors_origins = [
        origin.strip()
        for origin in os.getenv("CORS_ORIGINS", "*").split(",")
        if origin.strip()
    ]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    llm_client = LLMClient()

    @app.get("/health")
    async def health() -> dict[str, object]:
        return {
            "status": "ok",
            "llm_configured": llm_client.is_configured,
            "model": llm_client.settings.model,
        }

    @app.post("/api/v1/parse", response_model=ParseResponse)
    async def parse(request: ParseRequest) -> ParseResponse:
        try:
            return await llm_client.parse_utterance(request)
        except LLMProviderError as error:
            raise HTTPException(status_code=502, detail=str(error)) from error

    return app


app = create_app()
