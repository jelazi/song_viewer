#!/usr/bin/env bash
#
# Verify that a store artifact carries none of the third-party song sources.
#
# This is layer 3 of the flavour split (plans/store-release-plan.md §10). Layers
# 1 and 2 — the composition root and the const feature flags — are what actually
# remove the code. This script is what turns "I think it is excluded" into "I
# verified it is excluded", and it is what makes the claim defensible if an App
# Store reviewer asks where the song content comes from.
#
# Run it after every store build. Wire it into CI as a build-failing step.
#
# Usage:
#   tool/verify_store_build.sh [path-to-artifact]
#
# With no argument it checks the default Android app bundle path.

set -uo pipefail

# Binary input contains byte sequences that are invalid in a UTF-8 locale, which
# makes grep/sort abort with "Illegal byte sequence" — and an aborted scan looks
# exactly like a clean one. Force byte-wise handling so the scan cannot pass by
# failing.
export LC_ALL=C
export LANG=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Two severities, deliberately separated so the gate stays meaningful.
#
# BLOCKING — the actual scraping payload: reachable host names and the API
# token. If any of these are present the build can genuinely fetch third-party
# lyrics, which is blocker B1. Never upload such an artifact.
BLOCKING='velkyzpevnik\.cz|supermusic\.cz|pisnicky-akordy\.cz|zpevnik\.proscholy\.cz|songs\.worshipleaderapp\.com|worshipchords\.com|f66490724034594fbc'

# RESIDUE — bare identifiers and UI labels (enum names, method names, site
# display names). These carry no capability, but they show that some web code
# is still being compiled in, so they are worth reporting as a warning.
RESIDUE='ProScholy|superMusic|velkyZpevnik|PisnickyAkordy|WorshipChords|WorshipLeader'

artifact="${1:-}"

if [[ -z "$artifact" ]]; then
  # Default: the store flavour release bundle.
  artifact="$(find "$REPO_ROOT/build/app/outputs/bundle" -name '*.aab' 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$artifact" || ! -e "$artifact" ]]; then
  echo "verify_store_build: no artifact found."
  echo "Build one first, e.g.:"
  echo "  make store-android"
  exit 2
fi

echo "verify_store_build: scanning $artifact"

extract_strings() {
  local path="$1"
  if [[ -d "$path" ]]; then
    # .app bundle (iOS/macOS) — scan every file inside.
    find "$path" -type f -exec strings {} + 2>/dev/null
  else
    # .aab / .apk / .ipa are all zip archives.
    unzip -p "$path" 2>/dev/null | strings 2>/dev/null
  fi
}

# Extract once — the artifact is large and strings(1) is the slow part.
strings_dump="$(mktemp)"
trap 'rm -f "$strings_dump"' EXIT
extract_strings "$artifact" > "$strings_dump"

if [[ ! -s "$strings_dump" ]]; then
  echo "FAIL: extracted no strings at all — the scan is broken, not the build."
  exit 2
fi

blocking_hits="$(grep -aioE "$BLOCKING" "$strings_dump" | sort | uniq -c)"
residue_hits="$(grep -aoE "$RESIDUE" "$strings_dump" | sort | uniq -c)"

if [[ -n "$blocking_hits" ]]; then
  echo
  echo "FAIL: the store artifact contains third-party song source hosts or the API token."
  echo "This is blocker B1 (plans/store-release-plan.md §2) — do not upload it."
  echo
  echo "$blocking_hits"
  exit 1
fi

# Positive control: prove the scan can actually find a string in this artifact.
# Without this, a silently broken pipeline reads as a pass.
if ! grep -aiqE 'flutter' "$strings_dump"; then
  echo "FAIL: the scan found no 'flutter' string either — the pipeline is broken,"
  echo "so the clean result cannot be trusted. Treating as unverified."
  exit 2
fi

echo "OK: no third-party source hosts and no API token in the store artifact."
echo "    (positive control passed — the scan does read this artifact)"

if [[ -n "$residue_hits" ]]; then
  echo
  echo "WARNING: identifier/label residue is still present. No capability is"
  echo "exposed by these, but some web code is still being compiled in:"
  echo
  echo "$residue_hits"
fi
