#!/usr/bin/env bash
# Downloads each distinct schema version referenced in theme_schema_map.txt
# into schemas/<version>.json, once per version even if multiple theme
# files pin the same one.
set -euo pipefail

mkdir -p schemas

cut -f2,3 theme_schema_map.txt | sort -u | while IFS=$'\t' read -r version url; do
  if [ ! -f "schemas/${version}.json" ]; then
    echo "Downloading reportThemeSchema-${version}.json"
    curl -sfL "$url" -o "schemas/${version}.json"
  fi
done