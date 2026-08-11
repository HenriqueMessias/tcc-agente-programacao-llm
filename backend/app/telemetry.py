from dataclasses import dataclass, field

from .schemas import TelemetryMetrics


@dataclass
class TelemetryTracker:
    budget_usd: float = 0.50
    max_retries: int = 3
    metrics: TelemetryMetrics = field(default_factory=TelemetryMetrics)

    def record_compression(self, original_tokens: int, compressed_tokens: int, cycle: int) -> None:
        original_tokens = max(0, original_tokens)
        compressed_tokens = max(0, min(original_tokens, compressed_tokens))
        self.metrics.original_prompt_tokens += original_tokens
        self.metrics.compressed_prompt_tokens += compressed_tokens
        self.metrics.saved_tokens = self.metrics.original_prompt_tokens - self.metrics.compressed_prompt_tokens
        self.metrics.compression_ratio = (self.metrics.compressed_prompt_tokens / self.metrics.original_prompt_tokens) if self.metrics.original_prompt_tokens else 1.0
        self.metrics.cycle_number = cycle

    def record_cost(self, cost_usd: float) -> None:
        self.metrics.cost_usd += max(0.0, cost_usd)

    def can_continue(self, retry_count: int) -> bool:
        return retry_count < self.max_retries and self.metrics.cost_usd < self.budget_usd

    def snapshot(self) -> TelemetryMetrics:
        return self.metrics.model_copy(deep=True)

