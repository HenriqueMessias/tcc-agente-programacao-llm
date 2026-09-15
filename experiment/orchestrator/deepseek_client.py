"""Cliente DeepSeek (API compatível com OpenAI) com tool-calling e telemetria de custo.

ATENÇÃO: os preços por token abaixo são um placeholder — confirme o valor
vigente em https://platform.deepseek.com/api-docs/pricing antes de rodar as
execuções definitivas, e ajuste via as variáveis de ambiente
DEEPSEEK_PRICE_INPUT_PER_1M / DEEPSEEK_PRICE_OUTPUT_PER_1M se necessário.
"""
import asyncio
import os
import time

from openai import AsyncOpenAI

DEFAULT_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")
PRICE_INPUT_PER_1M = float(os.getenv("DEEPSEEK_PRICE_INPUT_PER_1M", "0.28"))
PRICE_OUTPUT_PER_1M = float(os.getenv("DEEPSEEK_PRICE_OUTPUT_PER_1M", "0.42"))


class DeepSeekClient:
    def __init__(self, api_key: str | None = None, model: str | None = None, temperature: float = 0.2) -> None:
        # timeout/max_retries explícitos: sem isso, uma chamada travada podia
        # ficar pendurada no timeout padrão do SDK (10 min) sem que o loop
        # nunca voltasse a checar orçamento/deadline (visto na prática no
        # bug de explosão de contexto de 14/09).
        self.client = AsyncOpenAI(api_key=api_key or os.environ["DEEPSEEK_API_KEY"], base_url="https://api.deepseek.com", timeout=90.0, max_retries=1)
        self.model = model or DEFAULT_MODEL
        self.temperature = temperature
        self.total_cost_usd = 0.0
        self.total_input_tokens = 0
        self.total_output_tokens = 0
        self.total_cache_tokens = 0
        self.call_log: list[dict] = []

    async def chat(self, messages: list[dict], tools: list[dict] | None = None):
        started = time.monotonic()
        # Retry com backoff para hiccups transitórios da API (visto na
        # prática nas execuções definitivas: falhas intermitentes e não
        # reprodutíveis — às vezes "choices" vazio, às vezes outro sintoma —
        # que não se repetem numa nova tentativa da MESMA chamada. Cobre
        # qualquer exceção na chamada em si, não só "choices" vazio, já que
        # a causa exata varia e o importante é não perder a execução inteira
        # por um problema de um único request.
        last_exc = None
        response = None
        for attempt in range(3):
            try:
                response = await self.client.chat.completions.create(
                    model=self.model,
                    temperature=self.temperature,
                    messages=messages,
                    tools=tools,
                )
                if response.choices:
                    break
                last_exc = RuntimeError(f"resposta da API DeepSeek sem 'choices': {response!r}")
            except Exception as exc:
                last_exc = exc
            if attempt < 2:
                await asyncio.sleep(2 * (attempt + 1))
        else:
            raise last_exc
        if response is None or not response.choices:
            raise last_exc
        usage = response.usage
        cached = getattr(usage.prompt_tokens_details, "cached_tokens", 0) if getattr(usage, "prompt_tokens_details", None) else 0
        cost = (usage.prompt_tokens / 1_000_000) * PRICE_INPUT_PER_1M + (usage.completion_tokens / 1_000_000) * PRICE_OUTPUT_PER_1M
        self.total_cost_usd += cost
        self.total_input_tokens += usage.prompt_tokens
        self.total_output_tokens += usage.completion_tokens
        self.total_cache_tokens += cached
        self.call_log.append({
            "timestamp": time.time(),
            "elapsed_s": time.monotonic() - started,
            "input_tokens": usage.prompt_tokens,
            "output_tokens": usage.completion_tokens,
            "cached_tokens": cached,
            "cost_usd": cost,
        })
        return response.choices[0].message
