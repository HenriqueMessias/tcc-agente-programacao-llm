"""Tipos normalizados compartilhados pelos clientes de LLM (DeepSeek/Anthropic),
para que state_machine.py trabalhe com uma única interface independente do
provedor (mensagens estilo OpenAI: assistant.tool_calls, role="tool")."""
from dataclasses import dataclass, field


@dataclass
class NormalizedFunction:
    name: str
    arguments: str  # JSON serializado, igual ao formato OpenAI


@dataclass
class NormalizedToolCall:
    id: str
    function: NormalizedFunction

    def model_dump(self) -> dict:
        return {"id": self.id, "type": "function", "function": {"name": self.function.name, "arguments": self.function.arguments}}


@dataclass
class NormalizedMessage:
    content: str | None
    tool_calls: list[NormalizedToolCall] = field(default_factory=list)
