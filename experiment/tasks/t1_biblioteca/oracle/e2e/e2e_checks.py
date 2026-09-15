"""Checks E2E (Playwright) para T1 — medem H2 (falhas de integração
front-end/back-end). Independentes dos testes que o agente escreveu."""
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

        async def flow_create_author_and_book():
            await page.goto(f"{base_url}/authors/new", timeout=15000)
            await page.fill("#author_name, input[name='author[name]']", "Jorge Amado")
            await page.click("input[type=submit], button[type=submit]")
            await page.wait_for_load_state("networkidle")
            await page.goto(f"{base_url}/authors", timeout=15000)
            content = await page.content()
            if "Jorge Amado" not in content:
                raise AssertionError("autor criado não aparece na listagem")

            await page.goto(f"{base_url}/books/new", timeout=15000)
            await page.fill("#book_title, input[name='book[title]']", "Capitães da Areia")
            select = page.locator("#book_author_id, select[name='book[author_id]']")
            await select.select_option(label="Jorge Amado")
            await page.click("input[type=submit], button[type=submit]")
            await page.wait_for_load_state("networkidle")
            await page.goto(f"{base_url}/books", timeout=15000)
            content = await page.content()
            if "Capitães da Areia" not in content or "Jorge Amado" not in content:
                raise AssertionError("livro criado (com autor associado) não aparece na listagem")

        async def flow_search():
            await page.goto(f"{base_url}/books?query=Capit%C3%A3es", timeout=15000)
            content = await page.content()
            if "Capitães da Areia" not in content:
                raise AssertionError("busca por título parcial não retornou o livro esperado")

        async def flow_validation_error():
            await page.goto(f"{base_url}/books/new", timeout=15000)
            await page.fill("#book_title, input[name='book[title]']", "")
            await page.click("input[type=submit], button[type=submit]")
            await page.wait_for_load_state("networkidle")
            still_has_form = await page.locator("#book_title, input[name='book[title]']").count() > 0
            if not still_has_form:
                raise AssertionError("após submissão inválida, o formulário deveria ser reexibido para correção")

        await check("criar_autor_e_livro_associado", flow_create_author_and_book)
        await check("busca_por_titulo_parcial", flow_search)
        await check("formulario_rejeita_titulo_vazio", flow_validation_error)

        await browser.close()
    return results
