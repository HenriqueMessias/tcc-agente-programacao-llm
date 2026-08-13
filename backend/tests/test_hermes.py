import pytest

from backend.app.compressor import TokenCompressor
from backend.app.schemas import SDDContract
from backend.app.telemetry import TelemetryTracker
from backend.app.paperclip import PaperclipGovernance
from backend.app.schemas import ExecutionMode, GenerateRequest


@pytest.mark.asyncio
async def test_compressor_removes_noise_and_duplicates():
    compressor = TokenCompressor()
    html = await compressor.compress_html_context("<!-- x --><style>x{}</style><main>  <p>ok</p> </main><script>x()</script>")
    assert html == "<main><p>ok</p></main>"
    errors = await compressor.compress_dom_errors([{"kind": "missing", "selector": "#x", "message": "  absent  "}, {"kind": "missing", "selector": "#x", "message": "absent"}])
    assert len(errors) == 1


def test_contract_rejects_empty_elements():
    with pytest.raises(ValueError):
        SDDContract(elements=[])


def test_telemetry_circuit_breaker():
    tracker = TelemetryTracker(budget_usd=0.5, max_retries=3)
    tracker.record_cost(0.5)
    assert not tracker.can_continue(1)
    tracker.record_compression(100, 60, 1)
    assert tracker.metrics.saved_tokens == 40
    assert tracker.metrics.compression_ratio == 0.6


@pytest.mark.asyncio
async def test_paperclip_approves_restricted_contract_and_baseline():
    contract = SDDContract(elements=[{"tag": "main", "id": "app"}])
    governance = PaperclipGovernance()
    restricted = await governance.approve(GenerateRequest(contract=contract, prompt="gerar", mode=ExecutionMode.RESTRICTED))
    baseline = await governance.approve(GenerateRequest(contract=contract, prompt="gerar", mode=ExecutionMode.BASELINE))
    assert restricted.approved and restricted.approval_id.startswith("sdd-")
    assert baseline.approved and baseline.approval_id.startswith("baseline-")


def test_groq_is_an_available_provider():
    request = GenerateRequest(contract=SDDContract(elements=[{"tag": "main"}]), prompt="gerar", provider="groq")
    assert request.provider == "groq"
