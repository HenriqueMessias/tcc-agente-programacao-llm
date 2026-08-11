from .schemas import SDDContract


class TDDRunner:
    """Small deterministic red/green harness executed before browser validation."""

    async def run(self, html: str, contract: SDDContract) -> list[dict]:
        failures: list[dict] = []
        if not html.strip():
            failures.append({"kind": "empty_output", "selector": None, "message": "a geração não produziu HTML"})
        if "<html" not in html.lower() and "<main" not in html.lower() and "<body" not in html.lower():
            failures.append({"kind": "invalid_html_shape", "selector": None, "message": "a saída não contém uma raiz HTML semântica"})
        for element in contract.elements:
            if element.id and f'id="{element.id}"' not in html and f"id='{element.id}'" not in html:
                failures.append({"kind": "tdd_missing_id", "selector": f"#{element.id}", "message": "teste unitário: ID não encontrado"})
        return failures

