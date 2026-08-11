from enum import Enum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator


class AgentState(str, Enum):
    IDLE = "IDLE"
    PLANNING = "PLANNING"
    GENERATING = "GENERATING"
    TESTING = "TESTING"
    COMPRESSING_PROMPT = "COMPRESSING_PROMPT"
    VALIDATING_DOM = "VALIDATING_DOM"
    RETRYING = "RETRYING"
    SUCCESS = "SUCCESS"
    FAILED_CIRCUIT_BREAK = "FAILED_CIRCUIT_BREAK"


class ExecutionMode(str, Enum):
    RESTRICTED = "restricted"
    BASELINE = "baseline"


class SDDElement(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str | None = Field(default=None, pattern=r"^[A-Za-z][A-Za-z0-9_:\-.]*$")
    tag: str = Field(min_length=1, max_length=32)
    classes: list[str] = Field(default_factory=list)
    attributes: dict[str, str] = Field(default_factory=dict)

    @field_validator("tag")
    @classmethod
    def normalize_tag(cls, value: str) -> str:
        value = value.strip().lower()
        if not value.isidentifier() and value not in {"h1", "h2", "h3", "p", "a", "img", "button", "input", "nav", "main", "section", "article", "header", "footer", "ul", "ol", "li", "form", "label", "div", "span"}:
            raise ValueError("tag deve ser um nome HTML válido")
        return value


class SDDContract(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(default="hermes-page", min_length=1, max_length=120)
    description: str = ""
    elements: list[SDDElement] = Field(min_length=1)
    required_ids: list[str] = Field(default_factory=list)
    required_tags: list[str] = Field(default_factory=list)
    required_classes: list[str] = Field(default_factory=list)
    acceptance_criteria: list[str] = Field(default_factory=list)

    @field_validator("required_ids", "required_classes")
    @classmethod
    def no_empty_values(cls, values: list[str]) -> list[str]:
        if any(not value.strip() for value in values):
            raise ValueError("a lista não pode conter valores vazios")
        return list(dict.fromkeys(value.strip() for value in values))

    @field_validator("required_tags")
    @classmethod
    def normalize_tags(cls, values: list[str]) -> list[str]:
        return list(dict.fromkeys(value.strip().lower() for value in values if value.strip()))


class GenerateRequest(BaseModel):
    contract: SDDContract
    prompt: str = Field(min_length=1, max_length=20_000)
    provider: str = Field(default="openai", pattern="^(openai|anthropic)$")
    model: str | None = None
    max_retries: int = Field(default=3, ge=0, le=10)
    budget_usd: float = Field(default=0.50, gt=0, le=100)
    mode: ExecutionMode = ExecutionMode.RESTRICTED


class DomError(BaseModel):
    kind: str
    selector: str | None = None
    message: str
    expected: Any = None
    actual: Any = None


class DomValidationResult(BaseModel):
    valid: bool
    errors: list[DomError] = Field(default_factory=list)
    checked_elements: int = 0


class TelemetryMetrics(BaseModel):
    original_prompt_tokens: int = 0
    compressed_prompt_tokens: int = 0
    saved_tokens: int = 0
    compression_ratio: float = 1.0
    cost_usd: float = 0.0
    cycle_number: int = 0


class GenerateResponse(BaseModel):
    status: AgentState
    html: str | None = None
    errors: list[DomError] = Field(default_factory=list)
    telemetry: TelemetryMetrics
    mode: ExecutionMode = ExecutionMode.RESTRICTED
    approval_id: str | None = None


class ApprovalResponse(BaseModel):
    approved: bool
    approval_id: str
    reason: str | None = None
    budget_usd: float


class SandboxValidationResponse(BaseModel):
    valid: bool
    tdd_passed: bool
    errors: list[DomError] = Field(default_factory=list)
    checked_elements: int = 0


class SandboxRequest(BaseModel):
    html: str = Field(max_length=2_000_000)
    contract: SDDContract
