#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

manifest() {
  local site="$1"
  while IFS= read -r -d '' path; do
    relative="${path#"$site"/}"
    printf '%s %s %s\n' "$(stat -c '%F' -- "$path")" "$(stat -c '%a' -- "$path")" "$relative"
    if [[ -f "$path" && ! -L "$path" ]]; then
      sha256sum -- "$path"
    fi
  done < <(find "$site" -mindepth 1 -print0 | LC_ALL=C sort -z)
}

"$repo/scripts/build-site.sh"
manifest "$repo/_site" > "$tmp/first.manifest"
"$repo/scripts/build-site.sh"
manifest "$repo/_site" > "$tmp/second.manifest"
cmp -- "$tmp/first.manifest" "$tmp/second.manifest"

for case_name in symlink fifo mode path cname secret canary fixture; do
  case_site="$tmp/$case_name"
  cp -a -- "$repo/_site" "$case_site"
  case "$case_name" in
    symlink) ln -s index.html "$case_site/link" ;;
    fifo) mkfifo "$case_site/fifo" ;;
    mode) chmod 0600 "$case_site/index.html" ;;
    path) cp "$case_site/index.html" "$case_site/bad name" ;;
    cname) printf 'js.pkg.re\n' > "$case_site/CNAME" ;;
    secret) printf '\nNPM_TOKEN=npm_abcdefghijklmnopqrstuvwxyz\n' >> "$case_site/index.html" ;;
    canary) printf 'drift\n' >> "$case_site/origin-health/v1.txt" ;;
    fixture) printf 'drift\n' >> "$case_site/nonproduction/redirect-marker-fixture-v0/index.html" ;;
  esac
  if "$repo/scripts/check-site.sh" "$case_site" >/dev/null 2>&1; then
    echo "validator accepted $case_name mutation" >&2
    exit 1
  fi
done
