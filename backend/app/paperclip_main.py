from fastapi import FastAPI

from .paperclip import PaperclipGovernance
from .schemas import ApprovalResponse, GenerateRequest

app = FastAPI(title="Paperclip Governance Service", version="1.0.0")
governance = PaperclipGovernance()


@app.post("/internal/v1/approve", response_model=ApprovalResponse)
async def approve(request: GenerateRequest) -> ApprovalResponse:
    return await governance.approve(request)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
