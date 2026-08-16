#!/usr/bin/env bash
# Downloads each distinct schema version referenced in theme_schema_map.txt
# into schemas/<version>.json, once per version even if multiple theme
# files pin the same one.
set -euo pipefail

mkdir -p schemas

# Some upstream Power BI schema versions contain duplicate enum entries, which
# are semantically harmless but make ajv-cli reject the schema before it can
# validate any theme files against it. Remove only those duplicate enum items.
normalize_schema() {
  python3 - "$1" <<'PY'
import json
import sys

path = sys.argv[1]

with open(path, encoding="utf-8") as f:
    schema = json.load(f)

changed = False

def dedupe(values):
    global changed
    seen = set()
    deduped = []
    for value in values:
        key = json.dumps(value, sort_keys=True, separators=(",", ":"))
        if key in seen:
            changed = True
            continue
        seen.add(key)
        deduped.append(value)
    return deduped

def walk(node):
    if isinstance(node, dict):
        enum = node.get("enum")
        if isinstance(enum, list):
            node["enum"] = dedupe(enum)
        for key, value in node.items():
            if key == "enum":
                continue
            walk(value)
    elif isinstance(node, list):
        for value in node:
            walk(value)

walk(schema)

if changed:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(schema, f, separators=(",", ":"))
        f.write("\n")
    print(f"Normalized duplicate enum values in {path}")
PY
}

cut -f2,3 theme_schema_map.txt | sort -u | while IFS=$'\t' read -r version url; do
  if [ ! -f "schemas/${version}.json" ]; then
    echo "Downloading reportThemeSchema-${version}.json"
    curl -sfL "$url" -o "schemas/${version}.json"
  fi
  # Keep this idempotent so an already-cached pre-fix schema file still gets
  # repaired on a later local rerun.
  normalize_schema "schemas/${version}.json"
done
