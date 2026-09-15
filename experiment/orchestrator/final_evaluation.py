"""Avaliação final independente (seção 6.5/6.7): roda os testes-oráculo dos
pesquisadores (não os testes que o próprio agente escreveu) contra a
aplicação final, para medir H1 (conformidade funcional) e H2/DOM/visual."""
import shutil
from pathlib import Path

from . import container as container_mod
from . import oracle_runner


async def evaluate(container: container_mod.ExecutionContainer, task_dir: Path, results_dir: Path, execution_id: str) -> dict:
    oracle_spec_src = task_dir / "oracle" / "spec"
    oracle_eval_dst = container.workspace_host / "oracle_eval"
    if oracle_eval_dst.exists():
        shutil.rmtree(oracle_eval_dst)
    shutil.copytree(oracle_spec_src, oracle_eval_dst)

    # O resultado é escrito dentro do workspace (bind-montado no host) e lido
    # direto do disco, em vez de depender do stdout do run_command — que é
    # truncado para os últimos 2500 caracteres (container.py) e corta o JSON
    # no meio para qualquer suíte com mais de poucos exemplos, fazendo o
    # parsing sempre cair no fallback 0/0 (visto na prática: acceptance
    # criteria sempre zerado nas primeiras execuções piloto).
    result_path = container.workspace_host / "oracle_eval_result.json"
    result_path.unlink(missing_ok=True)
    container_mod.run_command(container, "bundle exec rspec oracle_eval/ --format json --out oracle_eval_result.json", timeout_s=180)

    import json
    try:
        payload = json.loads(result_path.read_text(encoding="utf-8")) if result_path.exists() else {}
        summary = payload.get("summary", {})
        criteria_total = summary.get("example_count", 0)
        criteria_passed = criteria_total - summary.get("failure_count", 0)
    except (json.JSONDecodeError, OSError):
        criteria_total, criteria_passed = 0, 0

    container_mod.start_rails_server(container)
    oracle_report = await oracle_runner.run_oracles(container, task_dir, results_dir, execution_id, pass_number="final")

    return {
        "acceptance_criteria_total": criteria_total,
        "acceptance_criteria_passed": criteria_passed,
        "acceptance_criteria_ratio": (criteria_passed / criteria_total) if criteria_total else 0.0,
        **oracle_report,
    }
