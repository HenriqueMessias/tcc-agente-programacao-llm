# Hermes Backend

Pipeline Dockerizado para o ciclo cognitivo restritivo do TCC:

```text
hermes-api -> paperclip -> sandbox-runner
    |             |             |
    |             |             +-- TDD + Playwright DOM
    |             +-- aprovação SDD + orçamento
    +-- LLM + compressão + self-healing
```

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
playwright install chromium
$env:OPENAI_API_KEY = "..."
uvicorn app.main:app --reload
```

Com Docker:

```powershell
docker compose -f ../docker-compose.yml up --build
```

Os serviços são:

- `hermes-api`: API pública, geração, retries, compressão e telemetria;
- `paperclip`: governança interna do contrato SDD e aprovação do orçamento;
- `sandbox-runner`: execução isolada dos testes TDD e validação Playwright.

O `hermes_backend` é uma rede interna. Somente o `hermes-api` também possui acesso à rede externa para chamar o provedor LLM. Os serviços possuem limites de CPU/memória, `no-new-privileges` e remoção de capabilities Linux.

O endpoint `POST /api/v1/generate` recebe `contract`, `prompt`, `provider`, `model`, `max_retries`, `budget_usd` e `mode`. Use `mode: "restricted"` para o grupo experimental SDD/guardrails ou `mode: "baseline"` para o fluxo de controle. O endpoint `GET /api/v1/telemetry` retorna a última telemetria concluída.
