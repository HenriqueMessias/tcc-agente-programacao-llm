from pathlib import Path

from .schemas import DomError, DomValidationResult, SDDContract


class DomValidator:
    def __init__(self, timeout_ms: int = 10_000) -> None:
        self.timeout_ms = timeout_ms

    async def validate(self, html: str, contract: SDDContract) -> DomValidationResult:
        try:
            from playwright.async_api import async_playwright
        except ImportError as exc:
            raise RuntimeError("Playwright não está instalado; execute 'playwright install chromium'.") from exc

        errors: list[DomError] = []
        async with async_playwright() as playwright:
            browser = await playwright.chromium.launch(headless=True)
            page = await browser.new_page()
            try:
                await page.set_content(html, wait_until="domcontentloaded", timeout=self.timeout_ms)
                for element in contract.elements:
                    selector = f"#{element.id}" if element.id else element.tag
                    count = await page.locator(selector).count()
                    if count == 0:
                        errors.append(DomError(kind="missing_element", selector=selector, message="elemento obrigatório ausente", expected=element.tag, actual=0))
                        continue
                    locator = page.locator(selector).first
                    actual_tag = await locator.evaluate("el => el.tagName.toLowerCase()")
                    if actual_tag != element.tag:
                        errors.append(DomError(kind="wrong_tag", selector=selector, message="tag divergente", expected=element.tag, actual=actual_tag))
                    for css_class in element.classes:
                        if not await locator.evaluate("(el, c) => el.classList.contains(c)", css_class):
                            errors.append(DomError(kind="missing_class", selector=selector, message="classe obrigatória ausente", expected=css_class, actual=None))
                    for name, value in element.attributes.items():
                        if await locator.get_attribute(name) != value:
                            errors.append(DomError(kind="wrong_attribute", selector=selector, message="atributo divergente", expected={name: value}, actual=await locator.get_attribute(name)))
                for element_id in contract.required_ids:
                    if await page.locator(f"#{element_id}").count() == 0:
                        errors.append(DomError(kind="missing_id", selector=f"#{element_id}", message="ID obrigatório ausente", expected=element_id))
                for tag in contract.required_tags:
                    if await page.locator(tag).count() == 0:
                        errors.append(DomError(kind="missing_tag", selector=tag, message="tag obrigatória ausente", expected=tag))
                for css_class in contract.required_classes:
                    if await page.locator(f".{css_class}").count() == 0:
                        errors.append(DomError(kind="missing_class", selector=f".{css_class}", message="classe obrigatória ausente", expected=css_class))
            finally:
                await browser.close()
        return DomValidationResult(valid=not errors, errors=errors, checked_elements=len(contract.elements))

