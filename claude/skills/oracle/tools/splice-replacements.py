#!/usr/bin/env python3
"""Helpers for merging model-emitted replacement sections into a base design doc.

This is a library, not a CLI. Each review's merge logic is per-review — the
heading layout and which sections get replaced is specific. Import these
helpers into a small per-review merge script.

Example per-review script:

    from splice_replacements import demote_headings, extract_section, splice_range

    base = open("/tmp/round4-design.md").read()
    round5 = open("/tmp/round5-replacements.md").read()

    move3 = extract_section(round5, "# Replacement: Move 3 — ...", "\\n---\\n\\n# ")
    move3 = demote_headings_after_first(move3, new_h2="Move 3 — ...")

    merged = splice_range(
        base,
        start_marker="## Move 3 — Add diagnostics and SQLite instrumentation",
        end_marker="## Move 4 — Make public status harness-derived",
        replacement=move3.rstrip() + "\\n\\n---\\n\\n",
    )
"""
import re


def demote_headings(text: str) -> str:
    """Shift all markdown headings down one level: # -> ##, ## -> ###, etc."""
    out = []
    for line in text.split("\n"):
        m = re.match(r"^(#+)(\s+.*)$", line)
        if m:
            out.append("#" + m.group(1) + m.group(2))
        else:
            out.append(line)
    return "\n".join(out)


def demote_headings_after_first(text: str, new_h2: str) -> str:
    """Replace the first-line `# ...` heading with `## <new_h2>` and demote the rest.

    Common pattern for model-emitted sections like `# Replacement: Move N — ...`
    that need to drop into an `## Move N — ...` slot in the base doc.
    """
    lines = text.split("\n")
    assert lines and lines[0].startswith("# "), f"expected top-level heading, got: {lines[0]!r}"
    body = "\n".join(lines[1:])
    return f"## {new_h2}\n{demote_headings(body)}"


def extract_section(text: str, start_heading: str, end_pattern: str | None = None) -> str:
    """Pull a section starting at `start_heading`, ending before `end_pattern`
    (regex) or end-of-text. `start_heading` must be a literal string.

    Common end patterns:
        "\\n---\\s*\\n\\n(# [^\\n]+)"  — next top-level heading after a --- separator
        "\\n(# [^\\n]+)"              — next top-level heading (no separator)
    """
    idx = text.find(start_heading)
    if idx == -1:
        raise RuntimeError(f"section start not found: {start_heading!r}")
    search_from = idx + len(start_heading)
    if end_pattern:
        m = re.search(end_pattern, text[search_from:])
        end = search_from + m.start() if m else len(text)
    else:
        end = len(text)
    return text[idx:end].rstrip()


def splice_range(text: str, start_marker: str, end_marker: str, replacement: str) -> str:
    """Replace [start_marker, end_marker) with replacement. end_marker is kept.

    Both markers must be literal strings. start_marker must be unique in text
    (guards against ambiguous section boundaries in large docs).
    """
    start_idx = text.find(start_marker)
    if start_idx == -1:
        raise RuntimeError(f"start_marker not found: {start_marker!r}")
    if text.find(start_marker, start_idx + 1) != -1:
        raise RuntimeError(f"start_marker not unique: {start_marker!r}")
    end_idx = text.find(end_marker, start_idx + len(start_marker))
    if end_idx == -1:
        raise RuntimeError(f"end_marker not found after start: {end_marker!r}")
    return text[:start_idx] + replacement + text[end_idx:]


def strip_leading_prose(text: str, first_heading: str) -> str:
    """Drop any preamble before the first occurrence of `first_heading`.

    Useful when the model emits a "here's the design" paragraph before the
    canonical title.
    """
    idx = text.find(first_heading)
    return text[idx:] if idx > 0 else text
