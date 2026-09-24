#!/usr/bin/env python3
"""
assemble_and_repair.py

Turns the per-verse raw JSON cache (tools/build-data.sh's output) into the
slim, offline data/gita.json + data/chapters.json the plugin actually ships,
and writes a validation report.

Not executed against real API responses in the sandbox that produced this
plugin (no network there) — the field names below (slok, transliteration,
purohit.et, siva.et, chapter_number, verses_count, name, name_meaning,
name_translated, chapter_summary) are taken from the API's documented shape.
Re-check against a real response and adjust the KEY CONSTANTS below if any
field name differs before trusting the output.
"""
import argparse
import json
import re
import sys
from pathlib import Path

# ---- KEY CONSTANTS — check these against a real API response first -------
FIELD_SANSKRIT = "slok"
FIELD_TRANSLITERATION = "transliteration"
FIELD_PUROHIT = ("purohit", "et")
FIELD_SIVANANDA = ("siva", "et")

CHAPTER_FIELD_NUM = "chapter_number"
CHAPTER_FIELD_VERSES = "verses_count"
CHAPTER_FIELD_NAME = "translation"         # English title, e.g. "Arjuna Visada Yoga"
CHAPTER_FIELD_MEANING = ("meaning", "en")  # nested: {"en": ..., "hi": ...}
CHAPTER_FIELD_SUMMARY = ("summary", "en")  # nested: {"en": ..., "hi": ...}
# ----------------------------------------------------------------------------

# Verse-prefix and trailing-marker patterns, e.g. "1.1 " at the start and a
# Devanagari verse marker like "||१-१||" or "॥१-१॥" at the end.
PREFIX_RE = re.compile(r"^\s*\d+\.\d+\s+")
TRAILING_MARKER_RE = re.compile(r"\s*[|\u0964\u0965]{1,2}\s*[\u0966-\u096F०-९0-9\-]+\s*[|\u0964\u0965]{1,2}\s*$")

# Small, reviewable repair dictionary for the documented "qu" dropped-letters
# bug (e.g. "conered" -> "conquered", "adeacy" -> "adequacy"). Deliberately a
# whole-word map, not a blind "insert qu" regex, so real words are never
# corrupted by an over-eager substitution.
QU_REPAIRS = {
    "conered": "conquered", "conering": "conquering", "coners": "conquers", "conest": "conquest",
    "conests": "conquests", "coner": "conquer", "coneror": "conqueror", "conerors": "conquerors",
    "unconer": "unconquer", "unconered": "unconquered", "unconering": "unconquering", "adeacy": "adequacy", "adeate": "adequate", "adeately": "adequately",
    "eal": "equal", "eals": "equals", "eally": "equally", "eality": "equality",
    "eanimity": "equanimity", "eipped": "equipped", "eipment": "equipment",
    "conseence": "consequence", "conseences": "consequences", "conseently": "consequently",
    "conseent": "consequent", "reire": "require", "reired": "required", "reirement": "requirement",
    "reirements": "requirements", "reisite": "requisite", "ick": "quick", "ickly": "quickly",
    "iet": "quiet", "ietly": "quietly", "estion": "question", "estions": "questions",
    "estioning": "questioning", "estionable": "questionable", "ality": "quality",
    "alities": "qualities", "alify": "qualify", "alified": "qualified", "antity": "quantity",
    "antities": "quantities", "arrel": "quarrel", "een": "queen", "est": "quest",
}

NON_WORD_RE = re.compile(r"[a-z]{2,}", re.IGNORECASE)


def get_nested(d, *keys):
    cur = d
    for k in keys:
        if not isinstance(cur, dict) or k not in cur:
            return None
        cur = cur[k]
    return cur


def clean_text(s: str) -> str:
    if not s:
        return ""
    s = s.strip()
    s = PREFIX_RE.sub("", s)
    s = TRAILING_MARKER_RE.sub("", s)
    return s.strip()


def repair_qu(text: str) -> str:
    if not text:
        return text

    def repl(m):
        word = m.group(0)
        lower = word.lower()
        if lower in QU_REPAIRS:
            fixed = QU_REPAIRS[lower]
            # Preserve capitalisation of the original word.
            if word[0].isupper():
                fixed = fixed[0].upper() + fixed[1:]
            return fixed
        return word

    return NON_WORD_RE.sub(repl, text)


# A small English wordlist check would be ideal; to avoid a bundled
# dictionary dependency we instead flag *specific* known-bad fragments that
# indicate an unrepaired "qu" drop, plus any token containing no vowel at
# all (a strong signal of a mangled word). This is a lightweight linter, not
# a spellchecker — it is meant to catch regressions, not to be exhaustive.
SUSPECT_FRAGMENTS = ["coner", "adeac", "reire", "estion", "eanimity", "eipped", "conseen"]
VOWEL_RE = re.compile(r"[aeiouAEIOU]")


def find_suspects(text: str):
    if not text:
        return []
    hits = []
    for frag in SUSPECT_FRAGMENTS:
        if frag in text.lower():
            hits.append(frag)
    for word in re.findall(r"[A-Za-z]{4,}", text):
        if not VOWEL_RE.search(word):
            hits.append(word)
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw-dir", required=True)
    ap.add_argument("--chapters-raw", required=True)
    ap.add_argument("--chapters-out", required=True)
    ap.add_argument("--gita-out", required=True)
    ap.add_argument("--report-out", required=True)
    args = ap.parse_args()

    raw_dir = Path(args.raw_dir)
    chapters_raw = json.loads(Path(args.chapters_raw).read_text(encoding="utf-8"))

    # --- chapters.json --------------------------------------------------
    chapters_out = []
    for c in chapters_raw:
        chapters_out.append({
            "chapter": c.get(CHAPTER_FIELD_NUM),
            "name": c.get(CHAPTER_FIELD_NAME, ""),
            "meaning": get_nested(c, *CHAPTER_FIELD_MEANING) or "",
            "summary": clean_text(get_nested(c, *CHAPTER_FIELD_SUMMARY) or ""),
            "verseCount": c.get(CHAPTER_FIELD_VERSES),
        })
    chapters_out.sort(key=lambda x: x["chapter"] or 0)
    Path(args.chapters_out).write_text(json.dumps(chapters_out, ensure_ascii=False, indent=2), encoding="utf-8")

    # --- gita.json --------------------------------------------------------
    verses_out = []
    report = {"totalExpected": 0, "totalFetched": 0, "missing": [], "incomplete": [], "suspectWords": []}

    for cmeta in chapters_out:
        ch = cmeta["chapter"]
        vc = cmeta["verseCount"] or 0
        report["totalExpected"] += vc
        for vs in range(1, vc + 1):
            f = raw_dir / f"{ch}.{vs}.json"
            if not f.exists():
                report["missing"].append(f"{ch}.{vs}")
                continue
            try:
                raw = json.loads(f.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                report["missing"].append(f"{ch}.{vs} (corrupt cache file)")
                continue

            sanskrit = clean_text(raw.get(FIELD_SANSKRIT, ""))
            translit = clean_text(raw.get(FIELD_TRANSLITERATION, ""))
            purohit = repair_qu(clean_text(get_nested(raw, *FIELD_PUROHIT) or ""))
            sivananda = repair_qu(clean_text(get_nested(raw, *FIELD_SIVANANDA) or ""))

            if not sanskrit or not translit or (not purohit and not sivananda):
                report["incomplete"].append(f"{ch}.{vs}")

            for label, text in (("purohit", purohit), ("sivananda", sivananda)):
                suspects = find_suspects(text)
                if suspects:
                    report["suspectWords"].append({"verse": f"{ch}.{vs}", "translator": label, "suspects": suspects})

            verses_out.append({
                "chapter": ch,
                "verse": vs,
                "sanskrit": sanskrit,
                "transliteration": translit,
                "translations": {"purohit": purohit, "sivananda": sivananda},
            })
            report["totalFetched"] += 1

    Path(args.gita_out).write_text(json.dumps(verses_out, ensure_ascii=False, indent=2), encoding="utf-8")
    Path(args.report_out).write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Assembled {report['totalFetched']}/{report['totalExpected']} verses.", file=sys.stderr)
    if report["missing"]:
        print(f"{len(report['missing'])} verses missing — re-run build-data.sh to resume.", file=sys.stderr)
    if report["incomplete"]:
        print(f"{len(report['incomplete'])} verses incomplete (missing a field).", file=sys.stderr)
    if report["suspectWords"]:
        print(f"{len(report['suspectWords'])} possible unrepaired 'qu'-drop words — see {args.report_out}.", file=sys.stderr)


if __name__ == "__main__":
    main()
