from uuid import uuid4

from .schemas import ApprovalResponse, ExecutionMode, GenerateRequest


class PaperclipGovernance:
    """Local Paperclip-compatible boundary for SDD approval and budgets."""

    async def approve(self, request: GenerateRequest) -> ApprovalResponse:
        if request.mode == ExecutionMode.BASELINE:
            return ApprovalResponse(approved=True, approval_id=f"baseline-{uuid4().hex}", budget_usd=request.budget_usd)
        if not request.contract.elements:
            return ApprovalResponse(approved=False, approval_id=f"rejected-{uuid4().hex}", reason="SDD sem elementos obrigatórios", budget_usd=request.budget_usd)
        return ApprovalResponse(approved=True, approval_id=f"sdd-{uuid4().hex}", budget_usd=request.budget_usd)
