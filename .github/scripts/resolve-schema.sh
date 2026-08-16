#!/usr/bin/env bash
# For each file listed in theme_files.txt: checks it's valid JSON, requires
# a top-level "$schema" key, and requires that key to point at a
# reportThemeSchema-<version>.json file under microsoft/powerbi-desktop-
# samples's main branch (anything else is rejected without being fetched,
# so a PR can't make CI curl an arbitrary attacker-controlled URL).
#
# jq already has to parse each file to pull "$schema" out of it, so this
# also doubles as the JSON-syntax check -- a separate full pass over every
# file with a different tool first would just be reading each file twice
# for no extra coverage. Malformed JSON is caught right here instead.
#
# Writes theme_schema_map.txt: tab-separated <file> <version> <schema_url>
set -euo pipefail

SCHEMA_URL_PATTERN='^https://raw\.githubusercontent\.com/microsoft/powerbi-desktop-samples/main/Report%20Theme%20JSON%20Schema/reportThemeSchema-[0-9]+\.[0-9]+\.json$'

: > theme_schema_map.txt

while IFS= read -r f; do
  if ! schema_url=$(jq -r '."$schema" // empty' "$f" 2>/tmp/jq_err); then
    echo "::error file=$f::Invalid JSON syntax - $(cat /tmp/jq_err)"
    exit 1
  fi

  if [ -z "$schema_url" ]; then
    echo "::error file=$f::No \"\$schema\" key found. Every theme file must declare \"\$schema\" pointing at a reportThemeSchema-<version>.json URL from microsoft/powerbi-desktop-samples -- see developer-setup-guide.md, Option A."
    exit 1
  fi

  if ! echo "$schema_url" | grep -Eq "$SCHEMA_URL_PATTERN"; then
    echo "::error file=$f::\"\$schema\" value \"$schema_url\" is not a recognized reportThemeSchema URL from microsoft/powerbi-desktop-samples/main. Refusing to fetch it."
    exit 1
  fi

  version=$(echo "$schema_url" | sed -E 's#.*reportThemeSchema-([0-9]+\.[0-9]+)\.json#\1#')
  printf '%s\t%s\t%s\n' "$f" "$version" "$schema_url" >> theme_schema_map.txt
done < theme_files.txt

echo "Resolved \$schema per file:"
# column is a display nicety, not a hard dependency -- fall back to a
# plain dump if it's missing on whatever runner image this ends up on.
column -t -s $'\t' theme_schema_map.txt 2>/dev/null || cat theme_schema_map.txt