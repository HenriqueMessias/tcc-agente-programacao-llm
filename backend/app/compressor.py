import re
from collections.abc import Iterable


class TokenCompressor:
    """Lossy, deterministic compression for diagnostic context."""

    async def compress_dom_errors(self, raw_errors: list) -> list:
        unique: dict[tuple, dict] = {}
        for error in raw_errors:
            item = error.model_dump() if hasattr(error, "model_dump") else dict(error)
            message = re.sub(r"\s+", " ", str(item.get("message", ""))).strip()
            selector = str(item.get("selector") or "").strip()
            kind = str(item.get("kind", "unknown"))
            key = (kind, selector, message)
            unique[key] = {"kind": kind, "selector": selector or None, "message": message, "expected": item.get("expected"), "actual": item.get("actual")}
        return list(unique.values())

    async def compress_html_context(self, html_content: str) -> str:
        html = re.sub(r"<!--.*?-->", "", html_content, flags=re.S)
        html = re.sub(r"<script\b[^>]*>.*?</script\s*>", "", html, flags=re.I | re.S)
        html = re.sub(r"<style\b[^>]*>.*?</style\s*>", "", html, flags=re.I | re.S)
        html = re.sub(r"\s+", " ", html)
        html = re.sub(r">\s+<", "><", html)
        return html.strip()

    async def compress_history(self, messages: Iterable[dict]) -> list[dict]:
        result = []
        seen = set()
        for message in messages:
            content = re.sub(r"\s+", " ", str(message.get("content", ""))).strip()
            key = (message.get("role"), content)
            if content and key not in seen:
                result.append({"role": message.get("role", "user"), "content": content})
                seen.add(key)
        return result

