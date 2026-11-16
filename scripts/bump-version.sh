#!/bin/bash
# Bumps MARKETING_VERSION (x.y.z) in the Xcode project.
#   minor: y+1, z=0  (non-backward-compatible change to persisted settings/data)
#   patch: z+1       (everything else)
# x is never changed by this script. CURRENT_PROJECT_VERSION is left untouched.
#
# Usage: scripts/bump-version.sh <minor|patch> [path/to/project.pbxproj]

set -euo pipefail

kind="${1:-}"
root="$(cd "$(dirname "$0")/.." && pwd)"
pbxproj="${2:-$root/Go-E-Wallbox-Charging-App.xcodeproj/project.pbxproj}"

if [[ "$kind" != "minor" && "$kind" != "patch" ]]; then
    echo "Usage: $0 <minor|patch> [path/to/project.pbxproj]" >&2
    exit 1
fi

if [[ ! -f "$pbxproj" ]]; then
    echo "Error: $pbxproj not found" >&2
    exit 1
fi

versions="$(grep -E '^\s*MARKETING_VERSION = ' "$pbxproj" | sed -E 's/.*= *([^;]*);.*/\1/' | sort -u)"
count="$(printf '%s\n' "$versions" | grep -c . || true)"

if [[ "$count" -ne 1 ]]; then
    echo "Error: MARKETING_VERSION entries are not identical (found $count distinct values):" >&2
    printf '%s\n' "$versions" >&2
    exit 1
fi

current="$versions"
if [[ ! "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Error: '$current' is not in x.y.z format" >&2
    exit 1
fi

x="${BASH_REMATCH[1]}"
y="${BASH_REMATCH[2]}"
z="${BASH_REMATCH[3]}"

if [[ "$kind" == "minor" ]]; then
    new="$x.$((y + 1)).0"
else
    new="$x.$y.$((z + 1))"
fi

sed -E -i '' "s/^([[:space:]]*MARKETING_VERSION = )[^;]*;/\1$new;/" "$pbxproj"

echo "$current -> $new"
