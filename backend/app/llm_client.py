import json
import os
import re
from typing import Protocol

from .schemas import SDDContract


class LLMClient(Protocol):
    async def generate(self, prompt: str, model: str | None = None) -> tuple[str, int, int, float]: ...


def _extract_html(text: str) -> str:
    match = re.search(r"```(?:html)?\s*(.*?)```", text, flags=re.I | re.S)
    return (match.group(1) if match else text).strip()


class OpenAIClient:
    async def generate(self, prompt: str, model: str | None = None) -> tuple[str, int, int, float]:
        from openai import AsyncOpenAI
        response = await AsyncOpenAI(api_key=os.environ["OPENAI_API_KEY"]).responses.create(model=model or os.getenv("HERMES_OPENAI_MODEL", "gpt-4o-mini"), input=prompt)
        usage = response.usage
        return _extract_html(response.output_text), usage.input_tokens, usage.output_tokens, 0.0


class AnthropicClient:
    async def generate(self, prompt: str, model: str | None = None) -> tuple[str, int, int, float]:
        from anthropic import AsyncAnthropic
        response = await AsyncAnthropic(api_key=os.environ["ANTHROPIC_API_KEY"]).messages.create(model=model or os.getenv("HERMES_ANTHROPIC_MODEL", "claude-3-5-haiku-latest"), max_tokens=8_000, messages=[{"role": "user", "content": prompt}])
        text = "".join(block.text for block in response.content if hasattr(block, "text"))
        return _extract_html(text), response.usage.input_tokens, response.usage.output_tokens, 0.0


class GroqClient:
    async def generate(self, prompt: str, model: str | None = None) -> tuple[str, int, int, float]:
        from groq import AsyncGroq

        response = await AsyncGroq(api_key=os.environ["GROQ_API_KEY"]).chat.completions.create(
            model=model or os.getenv("HERMES_GROQ_MODEL", "llama-3.3-70b-versatile"),
            temperature=0.2,
            max_tokens=8_000,
            messages=[{"role": "user", "content": prompt}],
        )
        usage = response.usage
        text = response.choices[0].message.content or ""
        return _extract_html(text), usage.prompt_tokens, usage.completion_tokens, 0.0


def contract_prompt(contract: SDDContract, request: str) -> str:
    return "Gere somente HTML válido, sem markdown. Cumpra estritamente este contrato SDD:\n" + json.dumps(contract.model_dump(), ensure_ascii=False) + "\nPedido:\n" + request
