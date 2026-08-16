#!/usr/bin/env bash
# Finds every theme JSON file and writes their paths, one per line, to
# theme_files.txt for later steps to read. Fails fast if none are found.
set -euo pipefail

shopt -s nullglob
files=(themes/*.json)

if [ ${#files[@]} -eq 0 ]; then
  echo "::error::No theme JSON files found matching themes/*.json"
  exit 1
fi

echo "Found ${#files[@]} theme file(s):"
printf '  %s\n' "${files[@]}"
printf '%s\n' "${files[@]}" > theme_files.txt