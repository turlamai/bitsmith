#!/usr/bin/env python3
"""Design sync gate: the product UI may not drift from the prototype.

`design/` is the single source of truth for the UI (see AGENTS.md and
design/DESIGN.md). This gate fails when the shipped front end in `public/`
stops matching it:

1. `public/shared.css` is byte-identical to `design/prototype/shared.css`.
   The product stylesheet is a verbatim port; there is no second copy of
   the token values to keep in step by hand.
2. Each product page's inline <style> block starts with its prototype
   page's block. A page may append product-only rules, never edit the
   shared part.
3. No declared font size or font-size token is below 12px, in the
   prototype and in the product ("Exceptions: none", design/DESIGN.md).

Usage: python3 scripts/check-design-sync.py   (exit status 1 on findings)
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
PROTOTYPE = ROOT / "design" / "prototype"
PUBLIC = ROOT / "public"
PAGES = ("records.html", "image.html", "operations.html", "learn.html")
FLOOR_PX = 12.0
STYLE_BLOCK = re.compile(r"(?s)(?<=<style>).*?(?=</style>)")

# font-size: 9.5px | --text-xs: 12px | font: 650 11px/1.3 ...
SIZE_DECLARATIONS = (
    re.compile(r"font-size\s*:\s*([\d.]+)px"),
    re.compile(r"--text-[\w-]+\s*:\s*([\d.]+)px"),
    re.compile(r"(?<![\w-])font\s*:\s*[^;{}\"']*?([\d.]+)px"),
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def check_stylesheet(findings: list) -> None:
    product = read(PUBLIC / "shared.css")
    prototype = read(PROTOTYPE / "shared.css")
    if product != prototype:
        findings.append(
            "public/shared.css differs from design/prototype/shared.css; "
            "port the prototype stylesheet (it is a verbatim copy)"
        )


def check_pages(findings: list) -> None:
    for page in PAGES:
        product_match = STYLE_BLOCK.search(read(PUBLIC / page))
        prototype_match = STYLE_BLOCK.search(read(PROTOTYPE / page))
        if not product_match or not prototype_match:
            findings.append(f"{page}: inline <style> block missing on one side")
            continue
        product = product_match.group(0).replace("\r\n", "\n")
        prototype = prototype_match.group(0).replace("\r\n", "\n")
        if not product.startswith(prototype.rstrip()):
            findings.append(
                f"{page}: inline <style> no longer starts with the prototype "
                "block; port the prototype rules, product-only rules go last"
            )


def check_type_floor(findings: list) -> None:
    sources = sorted(
        list(PROTOTYPE.glob("*.css"))
        + list(PROTOTYPE.glob("*.html"))
        + list((ROOT / "design").glob("*.html"))
        + list(PUBLIC.glob("*.css"))
        + list(PUBLIC.glob("*.html"))
        + list(PUBLIC.glob("*.js"))
    )
    for path in sources:
        text = read(path)
        for pattern in SIZE_DECLARATIONS:
            for match in pattern.finditer(text):
                value = float(match.group(1))
                if value < FLOOR_PX:
                    shown = match.group(0).strip()
                    findings.append(
                        f"{path.relative_to(ROOT)}:{line_of(text, match.start())}: "
                        f"below the 12px floor: {shown}"
                    )


def main() -> int:
    findings: list = []
    check_stylesheet(findings)
    check_pages(findings)
    check_type_floor(findings)
    if findings:
        print("design sync: FAILED")
        for finding in findings:
            print(f"  - {finding}")
        return 1
    print("design sync: ok (stylesheet identical, page styles aligned, no type below 12px)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
