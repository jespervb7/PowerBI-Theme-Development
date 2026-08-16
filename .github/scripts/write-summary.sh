#!/usr/bin/env bash
# Appends a Markdown summary of the run to $GITHUB_STEP_SUMMARY: which
# schema version is newest upstream, and which version each theme file was
# actually validated against. Always runs, even on a failing run.
#
# Usage: write-summary.sh <latest-version>
set -euo pipefail

latest="${1:-unknown}"

{
  echo "### Power BI theme validation"
  echo ""
  echo "Latest schema available upstream: \`reportThemeSchema-${latest}.json\`"
  echo ""
  echo "| File | Validated against |"
  echo "| --- | --- |"
  while IFS=$'\t' read -r f version _; do
    echo "| \`$f\` | reportThemeSchema-${version}.json |"
  done < theme_schema_map.txt
} >> "$GITHUB_STEP_SUMMARY"