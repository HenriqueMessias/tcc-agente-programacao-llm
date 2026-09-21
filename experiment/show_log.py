#!/usr/bin/env python3
"""Imprime um resumo legível de um log.jsonl de execução (fases, checagens de
oráculo e métricas finais). Útil para inspecionar/demonstrar uma execução sem
ler o JSONL bruto linha a linha.

Uso:
    python show_log.py results/t3_autenticacao_restricted_seed1rep1_1789396523
    python show_log.py results/t3_autenticacao_restricted_seed1rep1_1789396523/log.jsonl
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def resolve_log_path(raw: str) -> Path:
    path = Path(raw)
    if not path.is_absolute():
        path = ROOT / path
    if path.is_dir():
        path = path / "log.jsonl"
    return path


def show_log(log_path: Path) -> None:
    for line in log_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        rec = json.loads(line)
        if rec["event"] == "phase_transition":
            print("FASE:", rec["phase"], "- aceita:", rec["accepted"])
        elif rec["event"] == "oracle_check":
            print("  oraculo em", rec["phase"], "- exit_code:", rec["exit_code"])
        elif rec["event"] == "execution_end":
            m = rec["final_metrics"]
            print(
                "FIM:", rec["status"],
                "- DOM:", m["dom_assertions_passed"], "/", m["dom_assertions_total"],
                "- visual:", m["visual_captures_passed"], "/", m["visual_captures_total"],
                "- E2E falhas:", m["e2e_failures"],
            )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "execution",
        help="Caminho do log.jsonl, ou do diretório da execução (ex.: results/<execution_id>)",
    )
    args = parser.parse_args()

    log_path = resolve_log_path(args.execution)
    if not log_path.exists():
        print(f"erro: {log_path} nao encontrado", file=sys.stderr)
        sys.exit(1)
    show_log(log_path)


if __name__ == "__main__":
    main()
