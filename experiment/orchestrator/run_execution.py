"""Ponto de entrada: roda uma execução (tarefa x condição x repetição x seed).

Uso:
    python -m orchestrator.run_execution --task t1_biblioteca --mode restricted --seed 1
"""
import argparse
import asyncio
import os
import time
from pathlib import Path

from . import container as container_mod
from . import final_evaluation
from . import oracle_runner
from . import state_machine
from .logging_ import ExecutionLogger

ROOT = Path(__file__).resolve().parent.parent
TASKS_DIR = ROOT / "tasks"
RESULTS_DIR = ROOT / "results"

# Configuráveis via env para permitir um teto mais conservador em execuções
# de validação/piloto sem alterar o valor do protocolo (US$5,00 / 25 min)
# usado nas execuções definitivas.
BUDGET_USD = float(os.getenv("EXECUTION_BUDGET_USD", "5.00"))
TIMEOUT_S = int(os.getenv("EXECUTION_TIMEOUT_S", str(25 * 60)))

# "Modelo LLM base fixo" do protocolo. O padrão aprovado na qualificação é
# DeepSeek V4 ("deepseek"). Usar "anthropic" é um DESVIO documentado do
# protocolo (ver experiment/README.md) — mantém o princípio de modelo único
# e idêntico nas duas condições, só troca qual modelo é esse.
def build_client(provider: str, temperature: float = 0.2):
    if provider == "deepseek":
        from .deepseek_client import DeepSeekClient
        return DeepSeekClient(temperature=temperature)
    if provider == "anthropic":
        from .anthropic_client import AnthropicClient
        return AnthropicClient(temperature=temperature)
    raise ValueError(f"provedor desconhecido: {provider}")


def load_dotenv() -> None:
    env_path = ROOT / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


def build_base_prompt(task_md: str) -> str:
    return (
        "Você vai desenvolver uma aplicação Ruby on Rails 8 com SQLite dentro do diretório /workspace (já vazio, com git inicializado). "
        "Use as ferramentas disponíveis (write_file, read_file, list_files, run_command) para criar o projeto do zero: "
        "1) rode 'rails new . --minimal --skip-bundle --force'; "
        "2) adicione ao Gemfile a linha \"gem 'json', '~> 2.9'\" (necessário: a versão mais recente do gem json é incompatível com Rails 8.1/Ruby 3.3 nesta imagem e quebra sessão/CSRF) e a linha \"gem 'rspec-rails', group: [:development, :test]\"; "
        "3) rode 'bundle install'; "
        "4) rode 'bin/rails generate rspec:install' (necessário para a avaliação, mesmo que você não escreva testes com RSpec).\n\n"
        f"{task_md}"
    )


async def run_execution(task: str, mode: str, seed: int, repetition: int, provider: str = "deepseek") -> dict:
    execution_id = f"{task}_{mode}_seed{seed}rep{repetition}_{int(time.time())}"
    task_dir = TASKS_DIR / task
    task_md = (task_dir / "task.md").read_text(encoding="utf-8")
    base_prompt = build_base_prompt(task_md)

    logger = ExecutionLogger(RESULTS_DIR, execution_id)
    logger.log("execution_start", task=task, mode=mode, seed=seed, repetition=repetition, provider=provider)

    client = build_client(provider, temperature=0.2)
    exec_container = container_mod.start(execution_id, RESULTS_DIR)
    logger.log("container_started", container_id=exec_container.container_id, host_port=exec_container.host_port)

    deadline = time.monotonic() + TIMEOUT_S
    started_wall = time.time()
    status = "unknown"
    cycle_result: dict = {}

    try:
        if mode == "restricted":
            pass_counter = {"n": 0}

            async def oracle_check(container):
                pass_counter["n"] += 1
                return await oracle_runner.run_oracles(container, task_dir, RESULTS_DIR, execution_id, pass_counter["n"])

            cycle_result = await state_machine.run_restricted_cycle(client, logger, exec_container, base_prompt, deadline, BUDGET_USD, oracle_check)
        else:
            cycle_result = await state_machine.run_baseline_cycle(client, logger, exec_container, base_prompt, deadline, BUDGET_USD)

        if cycle_result.get("failure"):
            status = f"malsucedida:{cycle_result['failure']}"
            final_metrics = {}
        else:
            final_metrics = await final_evaluation.evaluate(exec_container, task_dir, RESULTS_DIR, execution_id)
            status = "concluida"
    except Exception as exc:
        import traceback
        status = f"erro_infraestrutura:{exc}"
        final_metrics = {}
        logger.log("infra_error_traceback", traceback=traceback.format_exc())
    finally:
        elapsed_s = time.time() - started_wall
        logger.log(
            "execution_end",
            status=status,
            elapsed_s=elapsed_s,
            total_cost_usd=client.total_cost_usd,
            total_input_tokens=client.total_input_tokens,
            total_output_tokens=client.total_output_tokens,
            total_cache_tokens=client.total_cache_tokens,
            cycle_result=cycle_result,
            final_metrics=final_metrics,
        )
        logger.close()
        container_mod.stop(exec_container, keep_workspace=True)

    return {
        "execution_id": execution_id, "task": task, "mode": mode, "seed": seed, "repetition": repetition, "provider": provider,
        "status": status, "elapsed_s": elapsed_s,
        "total_cost_usd": client.total_cost_usd, "total_input_tokens": client.total_input_tokens,
        "total_output_tokens": client.total_output_tokens, "total_cache_tokens": client.total_cache_tokens,
        "final_metrics": final_metrics,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--task", required=True)
    parser.add_argument("--mode", choices=["baseline", "restricted"], required=True)
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--repetition", type=int, default=1)
    parser.add_argument("--provider", choices=["deepseek", "anthropic"], default="deepseek")
    args = parser.parse_args()
    load_dotenv()
    result = asyncio.run(run_execution(args.task, args.mode, args.seed, args.repetition, args.provider))
    import json
    print(json.dumps(result, ensure_ascii=False, indent=2, default=str))


if __name__ == "__main__":
    main()
