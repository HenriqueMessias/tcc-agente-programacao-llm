#!/usr/bin/env python3
"""Varre results/*/log.jsonl e monta uma linha por execução, pronta para a
análise estatística (seção 6.9) ou para conferência manual.

Uso:
    python summarize_results.py > results_summary.csv
    python summarize_results.py --task t1_biblioteca
"""
import argparse
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RESULTS_DIR = ROOT / "results"

FIELDNAMES = [
    "execution_id", "task", "mode", "provider", "seed", "repetition",
    "status", "elapsed_s", "total_cost_usd", "total_input_tokens", "total_output_tokens", "total_cache_tokens",
    "acceptance_criteria_total", "acceptance_criteria_passed", "acceptance_criteria_ratio",
    "dom_assertions_total", "dom_assertions_passed",
    "visual_captures_total", "visual_captures_passed",
    "e2e_total", "e2e_failures",
    "num_llm_calls", "max_input_tokens_single_call",
]


def read_log(log_path: Path) -> dict | None:
    start, end = None, None
    calls_input_tokens = []
    for line in log_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        rec = json.loads(line)
        if rec["event"] == "execution_start":
            start = rec
        elif rec["event"] == "execution_end":
            end = rec
        elif rec["event"] == "assistant_message" and rec.get("input_tokens") is not None:
            calls_input_tokens.append(rec["input_tokens"])
    if start is None or end is None:
        return None

    metrics = end.get("final_metrics") or {}
    row = {
        "execution_id": log_path.parent.name,
        "task": start.get("task"), "mode": start.get("mode"), "provider": start.get("provider"),
        "seed": start.get("seed"), "repetition": start.get("repetition"),
        "status": end.get("status"), "elapsed_s": end.get("elapsed_s"),
        "total_cost_usd": end.get("total_cost_usd"), "total_input_tokens": end.get("total_input_tokens"),
        "total_output_tokens": end.get("total_output_tokens"), "total_cache_tokens": end.get("total_cache_tokens"),
        "acceptance_criteria_total": metrics.get("acceptance_criteria_total"),
        "acceptance_criteria_passed": metrics.get("acceptance_criteria_passed"),
        "acceptance_criteria_ratio": metrics.get("acceptance_criteria_ratio"),
        "dom_assertions_total": metrics.get("dom_assertions_total"), "dom_assertions_passed": metrics.get("dom_assertions_passed"),
        "visual_captures_total": metrics.get("visual_captures_total"), "visual_captures_passed": metrics.get("visual_captures_passed"),
        "e2e_total": metrics.get("e2e_total"), "e2e_failures": metrics.get("e2e_failures"),
        "num_llm_calls": len(calls_input_tokens),
        "max_input_tokens_single_call": max(calls_input_tokens) if calls_input_tokens else None,
    }
    return row


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--task", help="Filtra por nome da tarefa (ex.: t1_biblioteca)")
    parser.add_argument("--results-dir", type=Path, default=RESULTS_DIR)
    parser.add_argument(
        "--final-only", action="store_true",
        help=(
            "Mantém só as 30 execuções definitivas (seed e repetição em 1..5): "
            "descarta pilotos (seeds fora desse intervalo) e, para cada combinação "
            "(task, mode, seed, repetition), mantém apenas a execução mais recente "
            "-- é o que substitui uma execução que bateu em erro_infraestrutura por "
            "um re-run com a mesma seed (seção 6.8-iii). Sem essa flag, results/ "
            "traz também os pilotos e as tentativas que foram re-rodadas."
        ),
    )
    args = parser.parse_args()

    rows = []
    for log_path in sorted(args.results_dir.glob("*/log.jsonl")):
        row = read_log(log_path)
        if row is None:
            print(f"aviso: {log_path} sem execution_start/execution_end completos, pulando", file=sys.stderr)
            continue
        if args.task and row["task"] != args.task:
            continue
        rows.append(row)

    if args.final_only:
        def in_design(row):
            try:
                return 1 <= int(row["seed"]) <= 5 and 1 <= int(row["repetition"]) <= 5
            except (TypeError, ValueError):
                return False

        latest_by_key: dict[tuple, dict] = {}
        skipped = 0
        for row in rows:
            if not in_design(row):
                skipped += 1
                continue
            key = (row["task"], row["mode"], row["seed"], row["repetition"])
            current = latest_by_key.get(key)
            # execution_id termina em timestamp Unix; comparação lexical == numérica aqui.
            if current is None or row["execution_id"] > current["execution_id"]:
                latest_by_key[key] = row
        if skipped:
            print(f"--final-only: descartadas {skipped} execuções fora do desenho (seed/repetição fora de 1..5, ex.: pilotos)", file=sys.stderr)
        rows = sorted(latest_by_key.values(), key=lambda r: r["execution_id"])

    writer = csv.DictWriter(sys.stdout, fieldnames=FIELDNAMES, extrasaction="ignore")
    writer.writeheader()
    for row in rows:
        writer.writerow(row)

    print(f"{len(rows)} execuções resumidas", file=sys.stderr)


if __name__ == "__main__":
    main()
