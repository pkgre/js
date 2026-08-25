#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$repo/_site"

rm -rf -- "$out"
install -d -m 0755 "$out/origin-health"
install -m 0644 "$repo/site-src/.nojekyll" "$out/.nojekyll"
install -m 0644 "$repo/site-src/index.html" "$out/index.html"
install -m 0644 "$repo/site-src/origin-health/v1.txt" "$out/origin-health/v1.txt"
"$repo/scripts/check-site.sh" "$out"
