#!/usr/bin/env bash
set -euo pipefail

if (( $# != 1 )); then
  echo "usage: $0 SITE_DIRECTORY" >&2
  exit 2
fi

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
site="${1%/}"
if [[ ! -d "$site" || -L "$site" ]]; then
  echo "site must be a real directory: $site" >&2
  exit 1
fi

while IFS= read -r -d '' path; do
  relative="${path#"$site"/}"
  if [[ ! "$relative" =~ ^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$ ]]; then
    printf 'invalid artifact path: %q\n' "$relative" >&2
    exit 1
  fi
  IFS=/ read -r -a components <<< "$relative"
  for component in "${components[@]}"; do
    if [[ "$component" == . || "$component" == .. ]]; then
      printf 'invalid artifact path component: %q\n' "$relative" >&2
      exit 1
    fi
  done
  if [[ -d "$path" && ! -L "$path" ]]; then
    expected_mode=755
  elif [[ -f "$path" && ! -L "$path" ]]; then
    expected_mode=644
  else
    printf 'artifact contains non-regular entry: %q\n' "$relative" >&2
    exit 1
  fi
  actual_mode="$(stat -c '%a' -- "$path")"
  if [[ "$actual_mode" != "$expected_mode" ]]; then
    printf 'artifact mode %s, expected %s: %q\n' "$actual_mode" "$expected_mode" "$relative" >&2
    exit 1
  fi
done < <(find "$site" -mindepth 1 -print0)

expected_files=$'.nojekyll\nindex.html\nnonproduction/redirect-marker-fixture-v0/index.html\norigin-health/v1.txt'
actual_files="$(find "$site" -type f -printf '%P\n' | LC_ALL=C sort)"
if [[ "$actual_files" != "$expected_files" ]]; then
  echo "unexpected artifact file set:" >&2
  printf '%s\n' "$actual_files" >&2
  exit 1
fi

if find "$site" -type f -name CNAME -print -quit | grep -q .; then
  echo 'artifact must not contain a GitHub Pages CNAME file' >&2
  exit 1
fi
if grep -ERIl -- '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----|(^|[[:space:]])(_authToken|NPM_TOKEN|GITHUB_TOKEN)[[:space:]]*=|npm_[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{20,}' "$site" >/dev/null; then
  echo 'artifact contains a secret-like value' >&2
  exit 1
fi
if grep -Eiq "<(script|style)([[:space:]>])|[[:space:]](style|on[a-z]+)[[:space:]]*=|rel[[:space:]]*=[[:space:]]*['\"]?stylesheet" "$site/index.html"; then
  echo 'index.html must not contain CSS or JavaScript' >&2
  exit 1
fi

expected_canary="$(mktemp)"
trap 'rm -f -- "$expected_canary"' EXIT
printf 'pkgre-origin js v1\n' > "$expected_canary"
cmp -- "$expected_canary" "$site/origin-health/v1.txt"
[[ "$(wc -c < "$site/origin-health/v1.txt")" -eq 19 ]]

fixture="$repo/fixtures/nonproduction-redirect-marker-v0"
[[ -f "$fixture/canonical.html" && ! -L "$fixture/canonical.html" ]]
[[ "$(stat -c '%a' -- "$fixture/canonical.html")" == 644 ]]
(
  cd "$fixture"
  sha256sum --check --status --strict canonical.sha256
)
cmp -- "$fixture/canonical.html" "$site/nonproduction/redirect-marker-fixture-v0/index.html"
