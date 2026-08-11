from fastapi import FastAPI, HTTPException

from .agent_engine import HermesEngine
from .schemas import GenerateRequest, GenerateResponse, TelemetryMetrics

app = FastAPI(title="Hermes Cognitive Engine", version="1.0.0")
engine = HermesEngine()


@app.post("/api/v1/generate", response_model=GenerateResponse)
async def generate(request: GenerateRequest) -> GenerateResponse:
    try:
        return await engine.run(request)
    except (RuntimeError, KeyError) as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.get("/api/v1/telemetry", response_model=TelemetryMetrics)
async def telemetry() -> TelemetryMetrics:
    return engine.last_telemetry

