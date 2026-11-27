#!/usr/bin/env python3
"""Check relative paths and Markdown heading fragments in inline links."""

from functools import cache
import html
import os
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {"archives-originales", "node_modules", "tmp"}
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
HEADING = re.compile(r"^ {0,3}#{1,6}\s+(.+?)\s*$")
LINK = re.compile(
    r"(?P<code>`+[^`\n]*`+)|!?\[[^]\n]*\]\(\s*"
    r'''(?P<target><[^>\n]+>|(?:\\.|[^\s()\\]|\([^()\n]*\))+)(?:\s+["'][^\n]*?["'])?\s*\)'''
)


@cache
def markdown_lines(path):
    lines = []
    fence = None
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        marker = FENCE.match(line)
        if fence:
            if marker and marker[1].startswith(fence) and not marker[2].strip():
                fence = None
            continue
        if marker:
            fence = marker[1]
        elif not line.startswith(("    ", "\t")):
            lines.append((number, line))
    return lines


@cache
def anchors(path):
    result = set()
    for _, line in markdown_lines(path):
        heading = HEADING.match(line)
        if not heading:
            continue
        title = re.sub(r"\s+#+$", "", heading[1])
        title = LINK.sub(lambda m: m["code"] or m[0].split("](", 1)[0].lstrip("!["), title)
        title = html.unescape(title).lower()
        slug = re.sub(r"[^\w\s-]", "", title).replace(" ", "-")
        anchor = slug
        suffix = 1
        while anchor in result:
            anchor = f"{slug}-{suffix}"
            suffix += 1
        result.add(anchor)
    return result


def markdown_files(root):
    for folder, dirs, names in os.walk(root):
        dirs[:] = sorted(d for d in dirs if not d.startswith(".") and d not in EXCLUDED)
        for name in sorted(names):
            if name.endswith(".md"):
                yield Path(folder) / name


def check_links(root):
    files = links = errors = 0
    for path in markdown_files(root):
        files += 1
        for number, line in markdown_lines(path):
            for match in LINK.finditer(line):
                if match["code"]:
                    continue
                raw = match["target"].strip("<>")
                raw = re.sub(r"\\([()])", r"\1", raw)
                if re.match(r"(?:[a-zA-Z][a-zA-Z0-9+.-]*:|//)", raw):
                    continue
                parts = urlsplit(raw)
                local = unquote(parts.path)
                links += 1
                if local.startswith("/"):
                    target = root / local.lstrip("/")
                else:
                    target = path.parent / local if local else path
                reason = None
                if not target.exists():
                    reason = "cible absente"
                elif parts.fragment and target.suffix == ".md" and target.is_file():
                    if unquote(parts.fragment) not in anchors(target.resolve()):
                        reason = "ancre absente"
                if reason:
                    print(f"{path.relative_to(root)}:{number}: {reason} · {raw}")
                    errors += 1
    print(f"{files} fichiers Markdown · {links} liens locaux · {errors} erreur(s)")
    return int(errors > 0)


if __name__ == "__main__":
    raise SystemExit(check_links(ROOT))
