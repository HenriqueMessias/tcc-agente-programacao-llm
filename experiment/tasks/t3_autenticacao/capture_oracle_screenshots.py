import asyncio
from pathlib import Path

import yaml
from playwright.async_api import async_playwright

BASE_URL = "http://localhost:3313"
TASK_DIR = Path(__file__).resolve().parent
OUT_DIR = TASK_DIR / "oracle" / "screenshots"


async def main():
    dom_assertions = yaml.safe_load((TASK_DIR / "oracle" / "dom_assertions.yml").read_text(encoding="utf-8"))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1366, "height": 768})
        for route in dom_assertions["routes"]:
            await page.goto(f"{BASE_URL}{route['path']}", wait_until="load")
            out_path = OUT_DIR / f"{route['slug']}.png"
            await page.screenshot(path=str(out_path))
            print(f"captured {route['slug']} -> {out_path}")
        await browser.close()


if __name__ == "__main__":
    asyncio.run(main())
