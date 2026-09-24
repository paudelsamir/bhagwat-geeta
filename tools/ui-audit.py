#!/usr/bin/env python3
"""ui-audit.py — static wiring tests for the Geeta Bar plugin.

Every button, toggle, select and injected callback is traced to a real
implementation. Run from the plugin root:

    python3 tools/ui-audit.py            # checks installed copy layout
    python3 tools/ui-audit.py --root .   # check another copy

Fails non-zero listing every broken wire. Pure stdlib.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[sys.argv.index("--root") + 1]) if "--root" in sys.argv else Path(__file__).resolve().parents[1]
COMP = ROOT / "components"
TABS = COMP / "tabs"
FAILURES = []


def fail(msg):
    FAILURES.append(msg)


def qml_files():
    return [ROOT / "Widget.qml"] + sorted(COMP.glob("*.qml")) + sorted(TABS.glob("*.qml"))


def read(p):
    return p.read_text(encoding="utf-8")


# ---------------------------------------------------------------- collectors
def strings_keys():
    return set(re.findall(r"readonly property (?:string|var) (\w+)", read(COMP / "Strings.qml")))


def qobject_api(path):
    src = read(path)
    funcs = set(re.findall(r"function (\w+)\s*\(", src))
    props = set(re.findall(r"property (?:var|string|int|real|bool|color) (\w+)", src))
    roprops = set(re.findall(r"readonly property (?:var|string|int|real|bool|color) (\w+)", src))
    return funcs | props | roprops


# ------------------------------------------------------------------- tests
def test_strings_refs():
    defined = strings_keys()
    for f in qml_files():
        if f.name == "Strings.qml":
            continue
        for m in re.finditer(r"Strings\.(\w+)", read(f)):
            if m.group(1) not in defined:
                fail(f"{f.name}: Strings.{m.group(1)} is not defined in Strings.qml")


def test_store_api():
    api = qobject_api(COMP / "Store.qml")
    for f in qml_files():
        if f.name == "Store.qml":
            continue
        for m in re.finditer(r"Store\.(\w+)", read(f)):
            if m.group(1) not in api:
                fail(f"{f.name}: Store.{m.group(1)} does not exist")


def test_gitadata_api():
    api = qobject_api(COMP / "GitaData.qml")
    for f in qml_files():
        if f.name == "GitaData.qml":
            continue
        for m in re.finditer(r"GitaData\.(\w+)", read(f)):
            if m.group(1) not in api:
                fail(f"{f.name}: GitaData.{m.group(1)} does not exist")


def test_settings_keys():
    widget = read(ROOT / "Widget.qml")
    m = re.search(r"readonly property var defaultSettings: \(\{(.*?)\}\)", widget, re.S)
    # strip "quoted" literals first so values like "07:00" can't match as keys
    body = re.sub(r'"[^"]*"', '""', m.group(1)) if m else ""
    defaults = set(re.findall(r"(\w+)\s*:", body))
    manifest = json.loads(read(ROOT / "manifest.json"))
    mdefaults = set(manifest["barWidget"]["defaults"])
    schema = {e["key"] for e in manifest["barWidget"]["schema"]}
    if defaults != mdefaults:
        fail(f"Widget defaultSettings {sorted(defaults)} != manifest defaults {sorted(mdefaults)}")
    if not schema >= defaults:
        fail(f"manifest schema missing keys: {sorted(defaults - schema)}")
    # every settings key read in QML must be a known default
    for f in qml_files():
        src = read(f)
        for pat in (r"liveSettings\.(\w+)", r"settings\s*\?\s*settings\.(\w+)"):
            for key in re.findall(pat, src):
                if key not in defaults:
                    fail(f"{f.name}: settings key '{key}' has no default")


def test_injected_callbacks():
    popup = read(COMP / "GeetaPopup.qml")
    provided = set(re.findall(r"property var (\w+Fn\w*)\s*:", popup))
    tab_ids = re.findall(r'\{\s*id:\s*"(\w+)"', popup)
    widget = read(ROOT / "Widget.qml")
    tab_files = []
    for tid in tab_ids:
        name = f"{tid[0].upper() + tid[1:]}Tab.qml"
        tab = TABS / name
        if not tab.is_file():
            fail(f"GeetaPopup: tab '{tid}' has no file {name}")
            continue
        tab_files.append(tab)
        block = re.search(rf"{tid[0].upper() + tid[1:]}Tab \{{(.*?)\}}", popup, re.S)
        if not block:
            fail(f"GeetaPopup: {name} is never instantiated")
            continue
        for fn in re.findall(r"(\w+Fn\w*)\s*:", block.group(1)):
            if fn not in provided:
                fail(f"GeetaPopup: {name} gets '{fn}' which GeetaPopup does not declare")
    # every *Fn called in tabs must be declared on the tab or passed in
    for tab in tab_files:
        src = read(tab)
        declared = set(re.findall(r"property var (\w+Fn\w*)\s*:", src))
        for fn in set(re.findall(r"(\w+Fn\w*)\s*\(", src)):
            if fn not in declared:
                fail(f"{tab.name}: calls '{fn}' without declaring it")


def test_no_modern_js():
    # Qt's QML engine is ES2017-era: trimEnd/padEnd/includes/??/?. throw
    # at runtime (seen live with trimEnd). Keep to ES2016 and older.
    banned = re.compile(r"\.trimEnd\s*\(|\.trimStart\s*\(|\.padEnd\s*\(|\.includes\s*\(|\.flat\s*\(|\?\?|\?\.") 
    for f in qml_files():
        for i, line in enumerate(read(f).splitlines(), 1):
            if banned.search(line):
                fail(f"{f.name}:{i}: post-ES2017 JS API: {line.strip()[:80]}")


def test_no_stubs():
    weasel = re.compile(r"console\.log\(|TODO|FIXME|UNTESTED|in the real plugin|swap .* below|capability sandbox|has not been|not.*verif", re.I)
    for f in qml_files():
        for i, line in enumerate(read(f).splitlines(), 1):
            if weasel.search(line):
                fail(f"{f.name}:{i}: stub/weasel content: {line.strip()[:90]}")


def test_glyphs():
    for f in qml_files():
        for m in re.finditer(r'glyph:\s*"([^"]*)"', read(f)):
            g = m.group(1)
            if not g:
                fail(f"{f.name}: empty icon glyph")
            elif g.startswith("\\u") and not re.fullmatch(r"(\\u[0-9a-fA-F]{4})+", g):
                fail(f"{f.name}: malformed glyph escape {g!r}")


def test_loaders_and_entrypoints():
    manifest = json.loads(read(ROOT / "manifest.json"))
    for kind, rel in manifest["entryPoints"].items():
        if not (ROOT / rel).is_file():
            fail(f"manifest entryPoint {kind}: {rel} does not exist")
    for f in qml_files():
        for m in re.finditer(r'source:\s*"([^"]+\.qml)"', read(f)):
            if not (f.parent / m.group(1)).is_file():
                fail(f"{f.name}: Loader source {m.group(1)} does not exist")


def test_tab_ids():
    popup = read(COMP / "GeetaPopup.qml")
    model_ids = set(re.findall(r'\{\s*id:\s*"(\w+)"', popup))
    for tid in model_ids:
        if f"{tid}Comp" not in popup:
            fail(f"GeetaPopup: {tid}Comp component missing")
    for case in re.findall(r'case\s*"(\w+)":\s*return\s*(\w+)Comp', popup):
        if case[0] not in model_ids:
            fail(f"GeetaPopup: switch case '{case[0]}' has no tabModel entry")


TESTS = [test_strings_refs, test_store_api, test_gitadata_api, test_settings_keys,
         test_injected_callbacks, test_no_stubs, test_no_modern_js, test_glyphs,
         test_loaders_and_entrypoints, test_tab_ids]


def main():
    if not (ROOT / "Widget.qml").is_file():
        print(f"no plugin at {ROOT}")
        return 2
    for t in TESTS:
        try:
            t()
        except Exception as e:  # a crashed test is a failed test
            fail(f"{t.__name__} crashed: {e}")
    if FAILURES:
        print(f"{len(FAILURES)} UI wiring failure(s):")
        for msg in FAILURES:
            print(f"  FAIL {msg}")
        return 1
    print(f"ok — {len(TESTS)} suites, {len(qml_files())} files, all wires connected")
    return 0


if __name__ == "__main__":
    sys.exit(main())
