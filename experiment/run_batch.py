#!/usr/bin/env python3
"""Roda o conjunto de execuções definitivas (seção 6.6): 3 tarefas x 5
repetições x 2 condições = 30 execuções, com ordem contrabalanceada por
repetição (ímpares: restricted -> baseline; pares: baseline -> restricted).

Uso:
    python run_batch.py --provider deepseek
    python run_batch.py --provider deepseek --tasks t1_biblioteca --repeats 1  # piloto rápido de 1 tarefa

Cada execução é sequencial (não paralela) nesta versão simples — o protocolo
permite até 4 contêineres simultâneos (seção 6.6), mas paralelizar exige mais
cuidado com portas/recursos; rodar sequencial primeiro é mais seguro para
confirmar que o custo por execução está dentro do esperado após a correção
do bug de explosão de contexto.

NOTA sobre "seed": nem a API do DeepSeek nem a da Anthropic garantem
determinismo total em loops de tool-calling mesmo com um seed — aqui o
"seed" é registrado como identificador de rastreio de cada repetição, não
como garantia de reprodutibilidade byte-a-byte.
"""
import argparse
import asyncio
import json
import time
from pathlib import Path

from orchestrator.run_execution import load_dotenv, run_execution

ALL_TASKS = ["t1_biblioteca", "t2_dashboard", "t3_autenticacao"]


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--provider", choices=["deepseek", "anthropic"], required=True)
    parser.add_argument("--tasks", nargs="+", default=ALL_TASKS)
    parser.add_argument("--repeats", type=int, default=5)
    parser.add_argument("--pilot", action="store_true", help="Roda só a execução-piloto (T1, 1 repetição, as duas condições) — seção 6.5")
    args = parser.parse_args()

    load_dotenv()

    if args.pilot:
        tasks, repeats = ["t1_biblioteca"], 1
    else:
        tasks, repeats = args.tasks, args.repeats

    plan = []
    for task in tasks:
        for repetition in range(1, repeats + 1):
            order = ["restricted", "baseline"] if repetition % 2 == 1 else ["baseline", "restricted"]
            for mode in order:
                plan.append((task, mode, repetition))

    print(f"Plano: {len(plan)} execuções ({args.provider})")
    results = []
    for i, (task, mode, repetition) in enumerate(plan, start=1):
        print(f"\n[{i}/{len(plan)}] {task} / {mode} / repetição {repetition} — iniciando ({time.strftime('%H:%M:%S')})")
        result = await run_execution(task, mode, seed=repetition, repetition=repetition, provider=args.provider)
        results.append(result)
        print(f"[{i}/{len(plan)}] status={result['status'][:80]} custo=${result['total_cost_usd']:.4f} tempo={result['elapsed_s']:.0f}s")

    out_path = Path(__file__).resolve().parent / "results" / f"batch_summary_{int(time.time())}.json"
    out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
    print(f"\nResumo do lote salvo em {out_path}")
    print("Rode 'python summarize_results.py > results_summary.csv' para consolidar todas as execuções em CSV.")


if __name__ == "__main__":
    asyncio.run(main())
