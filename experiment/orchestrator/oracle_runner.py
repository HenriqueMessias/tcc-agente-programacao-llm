"""Executa os oráculos independentes (seção 6.5/6.7) contra o servidor Rails
de uma execução: asserções de DOM por rota, comparação visual SSIM, e os
checks E2E definidos pelo pesquisador para a tarefa.

O GATE de retorno a GREEN (seção 6.3, fase 5) usa apenas DOM + visual — os
testes E2E são registrados para H2, mas não gatilham retry por si (é o que o
protocolo especifica literalmente).
"""
import importlib.util
import sys
import time
from pathlib import Path

import yaml
from playwright.async_api import async_playwright

import visual_diff


async def run_oracles(container, task_dir: Path, results_dir: Path, execution_id: str, pass_number: int) -> dict:
    oracle_dir = task_dir / "oracle"
    dom_assertions = yaml.safe_load((oracle_dir / "dom_assertions.yml").read_text(encoding="utf-8"))
    base_url = f"http://localhost:{container.host_port}"
    capture_dir = results_dir / execution_id / "captures" / f"pass_{pass_number}"
    capture_dir.mkdir(parents=True, exist_ok=True)

    dom_results = []
    visual_results = []

    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1366, "height": 768})
        for route_cfg in dom_assertions["routes"]:
            route = route_cfg["path"]
            route_name = route_cfg.get("name", route)
            try:
                await page.goto(f"{base_url}{route}", timeout=15000, wait_until="load")
                for selector in route_cfg.get("required_selectors", []):
                    count = await page.locator(selector).count()
                    dom_results.append({"route": route_name, "selector": selector, "found": count > 0})

                screenshot_path = capture_dir / f"{route_cfg['slug']}.png"
                await page.screenshot(path=str(screenshot_path))
                oracle_image = oracle_dir / "screenshots" / f"{route_cfg['slug']}.png"
                mask_image = oracle_dir / "screenshots" / f"{route_cfg['slug']}.mask.png"
                if oracle_image.exists():
                    visual_result = visual_diff.compare(screenshot_path, oracle_image, mask_image if mask_image.exists() else None)
                    visual_results.append({"route": route_name, **visual_result})
            except Exception as exc:  # falha de navegação conta como reprovação de todas as asserções da rota
                for selector in route_cfg.get("required_selectors", []):
                    dom_results.append({"route": route_name, "selector": selector, "found": False, "error": str(exc)})
        await browser.close()

    e2e_results = await _run_e2e_checks(oracle_dir, base_url)

    dom_passed = sum(1 for r in dom_results if r["found"])
    visual_passed = sum(1 for r in visual_results if r["passed"])
    e2e_failures = sum(1 for r in e2e_results if not r["passed"])

    gate_passed = (dom_passed == len(dom_results)) and (visual_passed == len(visual_results)) and len(dom_results) > 0

    return {
        "passed": gate_passed,
        "dom_assertions_total": len(dom_results),
        "dom_assertions_passed": dom_passed,
        "visual_captures_total": len(visual_results),
        "visual_captures_passed": visual_passed,
        "e2e_total": len(e2e_results),
        "e2e_failures": e2e_failures,
        "diff_report": {"dom": dom_results, "visual": visual_results, "e2e": e2e_results},
    }


async def _run_e2e_checks(oracle_dir: Path, base_url: str) -> list[dict]:
    e2e_file = oracle_dir / "e2e" / "e2e_checks.py"
    if not e2e_file.exists():
        return []
    spec = importlib.util.spec_from_file_location(f"e2e_checks_{time.time_ns()}", e2e_file)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return await module.run_e2e_checks(base_url)
