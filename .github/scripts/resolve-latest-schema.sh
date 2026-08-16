#!/usr/bin/env bash
# Queries the GitHub Contents API for the Report Theme JSON Schema folder
# in microsoft/powerbi-desktop-samples and works out which
# reportThemeSchema-<version>.json is newest, using `sort -V` since there's
# no published "latest" alias to rely on.
#
# Runs before the validation steps (which can fail) so its output -- used
# by both the staleness check and the summary -- is always available
# regardless of whether validation passes. Expects GH_TOKEN in the
# environment (the default GITHUB_TOKEN is enough; it just lifts the
# unauthenticated 60/hr GitHub API rate limit).
#
# Writes version=<x.y> (or version= if unresolved) to $GITHUB_OUTPUT.
set -euo pipefail

listing=$(curl -sf \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  "https://api.github.com/repos/microsoft/powerbi-desktop-samples/contents/Report%20Theme%20JSON%20Schema")

version=$(echo "$listing" \
  | jq -r '.[].name' \
  | grep -E '^reportThemeSchema-[0-9]+\.[0-9]+\.json$' \
  | sed -E 's/reportThemeSchema-([0-9]+\.[0-9]+)\.json/\1/' \
  | sort -V \
  | tail -n 1)

if [ -z "$version" ]; then
  echo "::warning::Could not determine the latest schema version from the GitHub API response, so the staleness check will be skipped. This does not affect pass/fail validation below."
else
  echo "Latest schema version found: $version"
fi

echo "version=$version" >> "$GITHUB_OUTPUT"