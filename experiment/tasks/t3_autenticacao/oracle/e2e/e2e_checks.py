"""Checks E2E (Playwright) para T3 — medem H2. Cobre o fluxo completo:
cadastro -> acesso à área protegida -> logout -> bloqueio de acesso."""
import time

from playwright.async_api import async_playwright


async def run_e2e_checks(base_url: str) -> list[dict]:
    results = []
    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1366, "height": 768})
        email = f"e2e{int(time.time())}@example.com"

        async def check(name, fn):
            try:
                await fn()
                results.append({"name": name, "passed": True})
            except Exception as exc:
                results.append({"name": name, "passed": False, "error": str(exc)})

        async def flow_protected_redirects_when_logged_out():
            await page.goto(f"{base_url}/protected", timeout=15000)
            if "/login" not in page.url:
                raise AssertionError(f"esperava redirecionamento para /login, obteve {page.url}")

        async def flow_signup_and_access_protected():
            await page.goto(f"{base_url}/signup", timeout=15000)
            await page.fill("#user_email", email)
            await page.fill("#user_password", "senha123")
            await page.click("#signup-form input[type=submit], #signup-form button[type=submit]")
            await page.wait_for_load_state("networkidle")
            if await page.locator("#protected-content").count() == 0:
                await page.goto(f"{base_url}/protected", timeout=15000)
            if await page.locator("#protected-content").count() == 0:
                raise AssertionError("após cadastro, área protegida não ficou acessível")

        async def flow_logout_blocks_access_again():
            await page.goto(f"{base_url}/protected", timeout=15000)
            logout_button = page.locator("#logout-button, button:has-text('Sair'), a:has-text('Sair')")
            if await logout_button.count() > 0:
                await logout_button.first.click()
                await page.wait_for_load_state("networkidle")
            await page.goto(f"{base_url}/protected", timeout=15000)
            if "/login" not in page.url:
                raise AssertionError("após logout, área protegida continuou acessível")

        await check("protected_redireciona_sem_login", flow_protected_redirects_when_logged_out)
        await check("cadastro_permite_acesso_a_area_protegida", flow_signup_and_access_protected)
        await check("logout_bloqueia_acesso_novamente", flow_logout_blocks_access_again)

        await browser.close()
    return results
