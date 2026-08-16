#!/usr/bin/env bash
# Validates each theme file against the schema version it declared in its
# own "$schema" key (already downloaded to schemas/<version>.json by
# download-schemas.sh). Runs every file even after a failure so one bad
# file doesn't hide problems in the rest, then exits non-zero overall if
# anything failed.
set -euo pipefail

status=0

while IFS=$'\t' read -r f version _; do
  echo "::group::Validating $f against reportThemeSchema-${version}.json"
  if ! ajv validate -s "schemas/${version}.json" -d "$f" --errors=text --all-errors; then
    echo "::error file=$f::Failed validation against reportThemeSchema-${version}.json"
    status=1
  fi
  echo "::endgroup::"
done < theme_schema_map.txt

exit $status