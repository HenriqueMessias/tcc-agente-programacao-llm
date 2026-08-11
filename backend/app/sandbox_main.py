from fastapi import FastAPI

from .dom_validator import DomValidator
from .schemas import SandboxRequest, SandboxValidationResponse
from .tdd_runner import TDDRunner

app = FastAPI(title="Hermes Sandbox Runner", version="1.0.0")
validator = DomValidator()
tdd_runner = TDDRunner()


@app.post("/internal/v1/validate", response_model=SandboxValidationResponse)
async def validate(request: SandboxRequest) -> SandboxValidationResponse:
    tdd_errors = await tdd_runner.run(request.html, request.contract)
    if tdd_errors:
        return SandboxValidationResponse(valid=False, tdd_passed=False, errors=tdd_errors)
    result = await validator.validate(request.html, request.contract)
    return SandboxValidationResponse(valid=result.valid, tdd_passed=True, errors=result.errors, checked_elements=result.checked_elements)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
