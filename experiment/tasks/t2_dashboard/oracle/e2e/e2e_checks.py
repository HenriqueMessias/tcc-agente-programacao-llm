"""Checks E2E (Playwright) para T2 — medem H2. Independentes do agente;
usam a rota /dashboard com filtros de data via query string."""
from playwright.async_api import async_playwright


async def run_e2e_checks(base_url: str) -> list[dict]:
    results = []
    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1366, "height": 768})

        async def check(name, fn):
            try:
                await fn()
                results.append({"name": name, "passed": True})
            except Exception as exc:
                results.append({"name": name, "passed": False, "error": str(exc)})

        async def flow_loads():
            response = await page.goto(f"{base_url}/dashboard", timeout=15000)
            if response.status != 200:
                raise AssertionError(f"dashboard retornou status {response.status}")
            if await page.locator("#metric-total").count() == 0:
                raise AssertionError("indicador de total não encontrado")

        async def flow_filter_via_form():
            await page.goto(f"{base_url}/dashboard", timeout=15000)
            if await page.locator("#filter-form").count() == 0:
                raise AssertionError("formulário de filtro não encontrado")
            await page.fill("input[name='start_date']", "2030-01-01")
            await page.fill("input[name='end_date']", "2030-01-02")
            await page.click("#filter-form input[type=submit]")
            await page.wait_for_load_state("networkidle")
            if "start_date=2030-01-01" not in page.url:
                raise AssertionError("submissão do filtro não propagou os parâmetros de data na URL")

        await check("dashboard_carrega_com_indicadores", flow_loads)
        await check("filtro_por_data_via_formulario", flow_filter_via_form)

        await browser.close()
    return results
