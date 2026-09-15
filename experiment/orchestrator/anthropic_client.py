"""Cliente Anthropic (Claude) com a MESMA interface de DeepSeekClient
(chat(messages, tools) -> NormalizedMessage), traduzindo o formato de
mensagens/ferramentas estilo OpenAI (usado por state_machine.py) para a API
nativa da Anthropic e de volta.

ATENÇÃO: preços por token abaixo são um placeholder — confirme o valor
vigente em https://www.anthropic.com/pricing antes de rodar execuções que
contam para a análise, e ajuste via ANTHROPIC_PRICE_INPUT_PER_1M /
ANTHROPIC_PRICE_OUTPUT_PER_1M se necessário.

Uso desta classe como "modelo LLM base fixo" é um DESVIO do protocolo
aprovado na qualificação (que especifica DeepSeek V4) — documentar
explicitamente na dissertação como mudança de escopo, mantendo intacto o
princípio de um único modelo fixo nas duas condições.
"""
import json
import os
import time

from anthropic import AsyncAnthropic

from .llm_client_base import NormalizedFunction, NormalizedMessage, NormalizedToolCall

DEFAULT_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-haiku-4-5-20251001")
PRICE_INPUT_PER_1M = float(os.getenv("ANTHROPIC_PRICE_INPUT_PER_1M", "1.00"))
PRICE_OUTPUT_PER_1M = float(os.getenv("ANTHROPIC_PRICE_OUTPUT_PER_1M", "5.00"))
MAX_TOKENS = 8192


def _to_anthropic_tools(tools: list[dict] | None) -> list[dict]:
    if not tools:
        return []
    return [
        {"name": t["function"]["name"], "description": t["function"].get("description", ""), "input_schema": t["function"]["parameters"]}
        for t in tools
    ]


def _to_anthropic_messages(messages: list[dict]) -> tuple[str, list[dict]]:
    system_parts = []
    converted = []
    for msg in messages:
        role = msg["role"]
        if role == "system":
            system_parts.append(msg["content"])
        elif role == "user":
            converted.append({"role": "user", "content": msg["content"]})
        elif role == "assistant":
            blocks = []
            if msg.get("content"):
                blocks.append({"type": "text", "text": msg["content"]})
            for tc in msg.get("tool_calls", []) or []:
                fn = tc["function"] if isinstance(tc, dict) else tc.function
                name = fn["name"] if isinstance(fn, dict) else fn.name
                arguments = fn["arguments"] if isinstance(fn, dict) else fn.arguments
                tool_id = tc["id"] if isinstance(tc, dict) else tc.id
                blocks.append({"type": "tool_use", "id": tool_id, "name": name, "input": json.loads(arguments or "{}")})
            converted.append({"role": "assistant", "content": blocks})
        elif role == "tool":
            # Todos os tool_result de um mesmo turno do assistente precisam ir
            # numa única mensagem "user" (Anthropic exige um bloco por
            # tool_use, todos juntos logo após a mensagem do assistente).
            block = {"type": "tool_result", "tool_use_id": msg["tool_call_id"], "content": msg["content"]}
            if converted and converted[-1]["role"] == "user" and isinstance(converted[-1]["content"], list) and converted[-1]["content"] and converted[-1]["content"][0].get("type") == "tool_result":
                converted[-1]["content"].append(block)
            else:
                converted.append({"role": "user", "content": [block]})
    return "\n".join(system_parts), converted


class AnthropicClient:
    def __init__(self, api_key: str | None = None, model: str | None = None, temperature: float = 0.2) -> None:
        self.client = AsyncAnthropic(api_key=api_key or os.environ["ANTHROPIC_API_KEY"])
        self.model = model or DEFAULT_MODEL
        self.temperature = temperature
        self.total_cost_usd = 0.0
        self.total_input_tokens = 0
        self.total_output_tokens = 0
        self.total_cache_tokens = 0
        self.call_log: list[dict] = []

    async def chat(self, messages: list[dict], tools: list[dict] | None = None) -> NormalizedMessage:
        started = time.monotonic()
        system, anthropic_messages = _to_anthropic_messages(messages)
        response = await self.client.messages.create(
            model=self.model,
            max_tokens=MAX_TOKENS,
            temperature=self.temperature,
            system=system or "Você é um agente de desenvolvimento de software.",
            messages=anthropic_messages,
            tools=_to_anthropic_tools(tools),
        )

        text_parts = [block.text for block in response.content if block.type == "text"]
        tool_calls = [
            NormalizedToolCall(id=block.id, function=NormalizedFunction(name=block.name, arguments=json.dumps(block.input)))
            for block in response.content
            if block.type == "tool_use"
        ]

        usage = response.usage
        cached = getattr(usage, "cache_read_input_tokens", 0) or 0
        cost = (usage.input_tokens / 1_000_000) * PRICE_INPUT_PER_1M + (usage.output_tokens / 1_000_000) * PRICE_OUTPUT_PER_1M
        self.total_cost_usd += cost
        self.total_input_tokens += usage.input_tokens
        self.total_output_tokens += usage.output_tokens
        self.total_cache_tokens += cached
        self.call_log.append({
            "timestamp": time.time(),
            "elapsed_s": time.monotonic() - started,
            "input_tokens": usage.input_tokens,
            "output_tokens": usage.output_tokens,
            "cached_tokens": cached,
            "cost_usd": cost,
        })

        return NormalizedMessage(content="\n".join(text_parts) if text_parts else None, tool_calls=tool_calls)
