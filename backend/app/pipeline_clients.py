import os

import httpx

from .dom_validator import DomValidator
from .paperclip import PaperclipGovernance
from .schemas import ApprovalResponse, GenerateRequest, SandboxRequest, SandboxValidationResponse
from .tdd_runner import TDDRunner


class PaperclipClient:
    def __init__(self) -> None:
        self.url = os.getenv("HERMES_PAPERCLIP_URL", "").rstrip("/")
        self.local = PaperclipGovernance()

    async def approve(self, request: GenerateRequest) -> ApprovalResponse:
        if not self.url:
            return await self.local.approve(request)
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(f"{self.url}/internal/v1/approve", json=request.model_dump(mode="json"))
            response.raise_for_status()
            return ApprovalResponse.model_validate(response.json())


class SandboxClient:
    def __init__(self) -> None:
        self.url = os.getenv("HERMES_SANDBOX_URL", "").rstrip("/")
        self.validator = DomValidator()
        self.tdd_runner = TDDRunner()

    async def validate(self, html: str, contract) -> SandboxValidationResponse:
        if not self.url:
            tdd_errors = await self.tdd_runner.run(html, contract)
            if tdd_errors:
                return SandboxValidationResponse(valid=False, tdd_passed=False, errors=tdd_errors)
            result = await self.validator.validate(html, contract)
            return SandboxValidationResponse(valid=result.valid, tdd_passed=True, errors=result.errors, checked_elements=result.checked_elements)
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(f"{self.url}/internal/v1/validate", json=SandboxRequest(html=html, contract=contract).model_dump(mode="json"))
            response.raise_for_status()
            return SandboxValidationResponse.model_validate(response.json())
