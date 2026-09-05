"""Extract the editorial catalog from the Rutio master DOCX.

The DOCX is the editorial source of truth. Tone is implementation metadata only:
the document does not assign it per row, so this file derives it conservatively
from the wording using a fixed, reviewable lexical rule.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from pathlib import Path

from docx import Document


TOKEN_RE = re.compile(r"\{([a-z_]+)\}")
ALLOWED_TOKENS = {"name", "streak_label", "progress"}
TOKEN_COLUMN_EMPTY = "—"

ENERGETIC_MARKERS = (
    "alcanza",
    "audaces",
    "abandones",
    "acción",
    "conquistar",
    "consigue",
    "energía",
    "fuerza",
    "intentar",
    "intento",
    "maestro",
    "oportunidad",
    "poder",
    "persevera",
    "valent",
    "victoria",
    "sigue:",
)

BALANCED_MARKERS = (
    "acción",
    "avanz",
    "camino",
    "constan",
    "constru",
    "decisión",
    "dirección",
    "elección",
    "esfuerzo",
    "hábito",
    "lleg",
    "mantener",
    "paso",
    "práctica",
    "progreso",
    "repet",
    "ritmo",
    "rutina",
    "sostener",
    "volver",
)


def folded(value: str) -> str:
    return "".join(
        char
        for char in unicodedata.normalize("NFD", value.lower())
        if unicodedata.category(char) != "Mn"
    )


def derive_tone(template: str) -> str:
    value = folded(template)
    if any(folded(marker) in value for marker in ENERGETIC_MARKERS):
        return "energetic"
    if any(folded(marker) in value for marker in BALANCED_MARKERS):
        return "balanced"
    return "gentle"


def source_metadata(origin: str) -> tuple[str, str | None]:
    if origin == "Original Rutio":
        return "original", None
    if origin.startswith("Refrán") or origin.startswith("Proverbio"):
        return "proverb", origin
    return "quote", origin


def tokens_in(template: str) -> list[str]:
    result: list[str] = []
    for token in TOKEN_RE.findall(template):
        if token not in result:
            result.append(token)
    return result


def expected_category(phrase_id: str) -> str:
    prefix, number_text = phrase_id.split("_")
    number = int(number_text)
    limits = {"personal": 50, "consistency": 100, "motivation": 150}
    if prefix not in limits or not 1 <= number <= limits[prefix]:
        raise ValueError(f"Unexpected phrase ID: {phrase_id}")
    return prefix


def extract(source: Path) -> dict[str, object]:
    document = Document(str(source))
    rows: list[tuple[str, str, str, str]] = []
    for table_index in (14, 15, 16):
        table = document.tables[table_index]
        for row in table.rows[1:]:
            values = tuple(cell.text.strip() for cell in row.cells)
            if len(values) != 4:
                raise ValueError(f"Catalog table {table_index} has an invalid row")
            rows.append(values)  # type: ignore[arg-type]

    if len(rows) != 300:
        raise ValueError(f"Expected 300 catalog rows, got {len(rows)}")

    phrases: list[dict[str, object]] = []
    for phrase_id, template, token_column, origin in rows:
        category = expected_category(phrase_id)
        actual_tokens = tokens_in(template)
        listed_tokens = [] if token_column == TOKEN_COLUMN_EMPTY else tokens_in(token_column)
        if listed_tokens != actual_tokens:
            raise ValueError(
                f"Token column mismatch for {phrase_id}: "
                f"listed={listed_tokens}, actual={actual_tokens}"
            )
        source_type, author = source_metadata(origin)
        phrases.append(
            {
                "id": phrase_id,
                "category": category,
                "tone": derive_tone(template),
                "sourceType": source_type,
                "author": author,
                "requiredTokens": actual_tokens,
                "weight": 100,
                "enabled": True,
                "template": template,
                "contentVersion": 1,
            }
        )

    return {
        "schemaVersion": 1,
        "catalogVersion": "1",
        "releaseVersion": 1,
        "locale": "es-ES",
        "phrases": phrases,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    catalog = extract(args.source)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
