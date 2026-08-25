#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$repo/_site"
fixture="$repo/fixtures/nonproduction-redirect-marker-v0"

[[ -f "$fixture/canonical.html" && ! -L "$fixture/canonical.html" ]]
(
  cd "$fixture"
  sha256sum --check --strict canonical.sha256
)
rm -rf -- "$out"
install -d -m 0755 "$out/origin-health" "$out/nonproduction/redirect-marker-fixture-v0"
install -m 0644 "$repo/site-src/.nojekyll" "$out/.nojekyll"
install -m 0644 "$repo/site-src/index.html" "$out/index.html"
install -m 0644 "$repo/site-src/origin-health/v1.txt" "$out/origin-health/v1.txt"
install -m 0644 "$fixture/canonical.html" "$out/nonproduction/redirect-marker-fixture-v0/index.html"
"$repo/scripts/check-site.sh" "$out"
