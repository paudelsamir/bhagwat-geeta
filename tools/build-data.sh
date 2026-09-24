#!/usr/bin/env bash
#
# build-data.sh — fetches every Bhagavad Gita verse from the public,
# MIT-licensed Bhagavad Gita API and writes a slim, offline data/gita.json
# plus data/chapters.json for the Geeta Bar plugin.
#
# Source: https://github.com/vedicscriptures/bhagavad-gita-api (MIT).
# Endpoints used: /chapters, /chapter/:ch, /slok/:ch/:sl
# (mirrored at https://vedicscriptures.github.io and https://bhagavadgitaapi.in
#  — pass --base to pick a mirror; check the source repo's Terms page before
#  redistributing derived data).
#
# THIS SCRIPT WAS NOT RUN in the sandbox that produced this plugin (no
# outbound network access there). It is written to the API's documented
# shape but has not been executed end-to-end against the live service —
# treat first run as a dry run and inspect data/gita.json before shipping.
#
# Usage:
#   tools/build-data.sh                 # fetch everything, resumable
#   tools/build-data.sh --base https://bhagavadgitaapi.in
#   tools/build-data.sh --throttle 0.3  # seconds between requests (default 0.5)
#   tools/build-data.sh --resume        # explicit resume (default behaviour anyway)
#   tools/build-data.sh --check-only    # just run the repair/validate pass on existing raw cache
#
# Requires: curl, jq

set -euo pipefail

BASE="https://vedicscriptures.github.io"
THROTTLE="0.5"
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --throttle) THROTTLE="$2"; shift 2 ;;
    --resume) shift ;; # default behaviour
    --check-only) CHECK_ONLY=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v jq   >/dev/null || { echo "jq is required" >&2; exit 1; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$ROOT_DIR/data"
RAW_DIR="$DATA_DIR/.raw"          # per-verse JSON cache, one file per verse — this is what makes the run resumable
mkdir -p "$RAW_DIR"

CHAPTERS_RAW="$DATA_DIR/.chapters_raw.json"
CHAPTERS_OUT="$DATA_DIR/chapters.json"
GITA_OUT="$DATA_DIR/gita.json"
REPORT_OUT="$DATA_DIR/validation-report.json"

log() { echo "[build-data] $*" >&2; }

fetch_json() {
  local url="$1"
  # -L: the static mirror 301s extensionless paths to a trailing slash
  curl -fsSL --retry 3 --retry-delay 2 "$url"
}

# --- 1. Chapter list: source of truth for verse counts, never hardcode ----
if [[ ! -f "$CHAPTERS_RAW" ]]; then
  log "Fetching /chapters ..."
  fetch_json "$BASE/chapters" > "$CHAPTERS_RAW"
fi

if [[ $CHECK_ONLY -eq 0 ]]; then
  # --- 2. Per-verse fetch, throttled and resumable ------------------------
  CHAPTER_COUNT=$(jq 'length' "$CHAPTERS_RAW")
  for (( ch=1; ch<=CHAPTER_COUNT; ch++ )); do
    verse_count=$(jq -r --argjson ch "$ch" '.[] | select(.chapter_number == $ch) | .verses_count' "$CHAPTERS_RAW")
    if [[ -z "$verse_count" || "$verse_count" == "null" ]]; then
      log "WARNING: could not determine verse count for chapter $ch from /chapters; skipping"
      continue
    fi
    for (( vs=1; vs<=verse_count; vs++ )); do
      out="$RAW_DIR/${ch}.${vs}.json"
      if [[ -f "$out" ]]; then
        continue # already fetched — resumable
      fi
      log "Fetching ${ch}.${vs} ..."
      if fetch_json "$BASE/slok/${ch}/${vs}" > "${out}.tmp"; then
        mv "${out}.tmp" "$out"
      else
        log "WARNING: failed to fetch ${ch}.${vs}, will retry on next run"
        rm -f "${out}.tmp"
      fi
      sleep "$THROTTLE"
    done
  done
fi

# --- 3. Clean + repair + assemble ------------------------------------------
#
# Known issues in the raw source text (per the plugin spec):
#  - Sanskrit/transliteration lines carry a leading "ch.vs " prefix and a
#    trailing Devanagari verse marker like "||१-१||" — both stripped here.
#  - Some English text has dropped the letters "qu" (e.g. "conered" for
#    "conquered", "adeacy" for "adequacy") — repaired with a small, reviewable
#    dictionary rather than a blind regex, to avoid corrupting real words.

python3 "$ROOT_DIR/tools/assemble_and_repair.py" \
  --raw-dir "$RAW_DIR" \
  --chapters-raw "$CHAPTERS_RAW" \
  --chapters-out "$CHAPTERS_OUT" \
  --gita-out "$GITA_OUT" \
  --report-out "$REPORT_OUT"

log "Done. Wrote $GITA_OUT, $CHAPTERS_OUT, and $REPORT_OUT"
log "Review $REPORT_OUT before shipping — it flags any verse missing Sanskrit,"
log "transliteration, or both English translations, and any remaining"
log "suspicious non-words after the qu-repair pass."
