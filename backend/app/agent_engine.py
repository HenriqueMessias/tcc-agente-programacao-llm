from .compressor import TokenCompressor
from .llm_client import AnthropicClient, GroqClient, LLMClient, OpenAIClient, contract_prompt
from .pipeline_clients import PaperclipClient, SandboxClient
from .schemas import AgentState, GenerateRequest, GenerateResponse
from .telemetry import TelemetryTracker


def estimate_tokens(text: str) -> int:
    return max(1, len(text) // 4)


class HermesEngine:
    def __init__(self, llm: LLMClient | None = None, compressor: TokenCompressor | None = None, paperclip: PaperclipClient | None = None, sandbox: SandboxClient | None = None) -> None:
        self.llm = llm
        self.compressor = compressor or TokenCompressor()
        self.paperclip = paperclip or PaperclipClient()
        self.sandbox = sandbox or SandboxClient()
        self.last_telemetry = TelemetryTracker().snapshot()

    async def run(self, request: GenerateRequest) -> GenerateResponse:
        tracker = TelemetryTracker(budget_usd=request.budget_usd, max_retries=request.max_retries)
        client = self.llm or ({"openai": OpenAIClient, "anthropic": AnthropicClient, "groq": GroqClient}[request.provider]())
        approval = await self.paperclip.approve(request)
        if not approval.approved:
            return GenerateResponse(status=AgentState.FAILED_CIRCUIT_BREAK, errors=[{"kind": "governance_rejection", "message": approval.reason or "SDD rejeitado"}], telemetry=tracker.snapshot(), mode=request.mode, approval_id=approval.approval_id)
        prompt = contract_prompt(request.contract, request.prompt)
        html = None
        errors = []
        retry_count = 0
        while True:
                state = AgentState.GENERATING if retry_count == 0 else AgentState.RETRYING
                if retry_count:
                    compact_errors = await self.compressor.compress_dom_errors(errors)
                    compact_html = await self.compressor.compress_html_context(html or "")
                    prompt = contract_prompt(request.contract, request.prompt) + f"\nFalhas estruturadas: {compact_errors}\nHTML anterior: {compact_html}"
                    prompt = "\n".join((await self.compressor.compress_history([{"role": "user", "content": prompt}]))[0].values())
                generated, input_tokens, output_tokens, cost = await client.generate(prompt, request.model)
                html = generated
                tracker.record_cost(cost)
                tracker.record_compression(input_tokens, estimate_tokens(prompt), retry_count + 1)
                validation = await self.sandbox.validate(html, request.contract)
                errors = validation.errors
                if validation.valid:
                    tracker.metrics.cycle_number = retry_count + 1
                    self.last_telemetry = tracker.snapshot()
                    return GenerateResponse(status=AgentState.SUCCESS, html=html, telemetry=tracker.snapshot(), mode=request.mode, approval_id=approval.approval_id)
                retry_count += 1
                if not tracker.can_continue(retry_count):
                    self.last_telemetry = tracker.snapshot()
                    return GenerateResponse(status=AgentState.FAILED_CIRCUIT_BREAK, html=html, errors=errors, telemetry=tracker.snapshot(), mode=request.mode, approval_id=approval.approval_id)
