#!/usr/bin/env bash
set -euo pipefail

if (( $# > 1 )); then
  echo "usage: $0 [PKGRE_SOURCE_REPOSITORY]" >&2
  exit 2
fi

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
release="$repo/bootstrap/js-v0.1.0"
source_repo="${1:-$repo/../pkgre}"
tag=js/v0.1.0
tag_object=ba2ace0c3efd55160b79a620f3ec548305fa7b34
commit=066293df21743cbf41fb571a38f2bb94059e7274
archive_sha1=003edfeff6cd091e308cba2daaf737ad843cf073
archive_sha256=07e3bbe05bffd0994601324a6519621dd93c6990e9350b04019c8366942207e3
archive_integrity='sha512-bRuXdwAzbk7TSAcL11WeveyAnUf+VKQdmtkq60GnF83Ofc3piXia7ALSTWQX5+DSMBmKILghh3B2pd1hWNjkjg=='
catalog_sha256=b92834fb5571e00c01c389f776ba1e4749ab11be8b64f7ee5beaa8a34507fafc
evidence_time=2026-08-25T23:27:24.000Z
archive="$release/archives/$archive_sha256.tgz"

[[ -d "$release" && ! -L "$release" ]]
[[ -d "$source_repo/.git" || -f "$source_repo/.git" ]]
source_repo="$(cd "$source_repo" && pwd)"
tmp="$(mktemp -d)"
worktree_added=false
cleanup() {
  if $worktree_added; then git -C "$source_repo" worktree remove --force "$tmp/source" >/dev/null 2>&1 || true; fi
  rm -rf -- "$tmp"
}
trap cleanup EXIT

while IFS= read -r -d '' path; do
  relative="${path#"$release"/}"
  if [[ ! "$relative" =~ ^[A-Za-z0-9@._~-]+(/[A-Za-z0-9@._~-]+)*$ ]]; then
    printf 'invalid bootstrap path: %q\n' "$relative" >&2
    exit 1
  fi
  if [[ -d "$path" && ! -L "$path" ]]; then
    expected_mode=755
  elif [[ -f "$path" && ! -L "$path" ]]; then
    expected_mode=644
  else
    printf 'bootstrap contains non-regular entry: %q\n' "$relative" >&2
    exit 1
  fi
  actual_mode="$(stat -c '%a' -- "$path")"
  if [[ "$actual_mode" != "$expected_mode" ]]; then
    printf 'bootstrap mode %s, expected %s: %q\n' "$actual_mode" "$expected_mode" "$relative" >&2
    exit 1
  fi
done < <(find "$release" -mindepth 1 -print0)
actual_files="$(find "$release" -type f -printf '%P\n' | LC_ALL=C sort)"
expected_files="$({ printf '%s\n' SHA256SUMS; sed -n 's/^[0-9a-f]\{64\}  //p' "$release/SHA256SUMS"; } | LC_ALL=C sort)"
if [[ "$actual_files" != "$expected_files" ]]; then
  echo 'bootstrap file inventory differs from SHA256SUMS' >&2
  diff -u <(printf '%s\n' "$expected_files") <(printf '%s\n' "$actual_files") >&2 || true
  exit 1
fi
(
  cd "$release"
  sha256sum --check --strict SHA256SUMS
)
[[ "$(sha256sum "$release/catalog.json" | cut -d' ' -f1)" == "$catalog_sha256" ]]
[[ "$(wc -c < "$archive")" -eq 16717 ]]
[[ "$(sha1sum "$archive" | cut -d' ' -f1)" == "$archive_sha1" ]]
[[ "$(sha256sum "$archive" | cut -d' ' -f1)" == "$archive_sha256" ]]
cmp -- "$archive" "$release/site-routes/packages/$archive_sha256.tgz"
cmp -- "$archive" "$release/site-final/packages/$archive_sha256.tgz"
if find "$release" -type f -name CNAME -print -quit | grep -q .; then
  echo 'dormant bootstrap must not contain a GitHub Pages CNAME file' >&2
  exit 1
fi
if find "$release" -type f ! -name '*.tgz' -print0 | xargs -0 grep -EIl -- '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----|(^|[[:space:]])(_authToken|NPM_TOKEN|GITHUB_TOKEN)[[:space:]]*=|npm_[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{20,}' >/dev/null; then
  echo 'dormant bootstrap contains a secret-like value' >&2
  exit 1
fi

[[ "$(git -C "$source_repo" rev-parse "refs/tags/$tag^{tag}")" == "$tag_object" ]]
[[ "$(git -C "$source_repo" cat-file -t "$tag_object")" == tag ]]
[[ "$(git -C "$source_repo" rev-parse "refs/tags/$tag^{commit}")" == "$commit" ]]
tag_epoch="$(git -C "$source_repo" for-each-ref --format='%(taggerdate:unix)' "refs/tags/$tag")"
[[ "$(date -u -d "@$tag_epoch" +%Y-%m-%dT%H:%M:%S.000Z)" == "$evidence_time" ]]
git -C "$source_repo" worktree add --detach "$tmp/source" "$commit" >/dev/null
worktree_added=true

nix_command=(nix --extra-experimental-features 'nix-command flakes')
client="$("${nix_command[@]}" build --no-link --print-out-paths "$tmp/source#js-client-node-minimum")"
indexer="$("${nix_command[@]}" build --no-link --print-out-paths "$tmp/source#js")"
[[ "$("$client/bin/node" --version)" == v24.15.0 ]]
[[ "$("$client/bin/npm" --version)" == 12.0.2 ]]
[[ "$("$client/bin/node" --input-type=module - "$archive" <<'EOF'
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
const bytes = readFileSync(process.argv[2]);
process.stdout.write(`sha512-${createHash("sha512").update(bytes).digest("base64")}`);
EOF
)" == "$archive_integrity" ]]
"$client/bin/node" --input-type=module - "$release/catalog.json" "$tag_object" "$commit" "$archive_sha1" "$archive_sha256" "$archive_integrity" "$evidence_time" <<'EOF'
import { readFileSync } from "node:fs";
const [catalogPath, tagObject, commit, sha1, sha256, integrity, evidenceTime] = process.argv.slice(2);
const catalog = JSON.parse(readFileSync(catalogPath, "utf8"));
const record = catalog.packages?.[0]?.versions?.[0];
const expected = {
  catalog: [catalog.schema, catalog.registry, catalog.minimumAgeSeconds, catalog.evaluationTime, catalog.packages.length],
  identity: [catalog.packages[0].name, record.version, catalog.packages[0].distTags.latest],
  evidence: [record.publishedAt, record.admittedAt],
  source: [record.source.kind, record.source.repository, record.source.tag, record.source.tagObject, record.source.commit, record.source.bytes, record.source.sha1, record.source.sha256, record.source.integrity, record.source.url],
};
const wanted = {
  catalog: ["pkgre-js-catalog-v1", "main", 2592000, evidenceTime, 1],
  identity: ["pkgre-js", "0.1.0", "0.1.0"],
  evidence: [evidenceTime, evidenceTime],
  source: ["first-party", "https://github.com/pkgre/pkgre", "js/v0.1.0", tagObject, commit, 16717, sha1, sha256, integrity, `https://js.pkg.re/packages/${sha256}.tgz`],
};
if (JSON.stringify(expected) !== JSON.stringify(wanted)) throw new Error("bootstrap catalog provenance differs");
EOF

mkdir "$tmp/pack-a" "$tmp/pack-b"
for run in a b; do
  mkdir "$tmp/home-$run" "$tmp/cache-$run"
  (
    cd "$tmp/source/js"
    HOME="$tmp/home-$run" npm_config_cache="$tmp/cache-$run" npm_config_audit=false npm_config_fund=false npm_config_ignore_scripts=true npm_config_offline=true npm_config_update_notifier=false \
      "$client/bin/npm" pack --ignore-scripts --json --pack-destination "$tmp/pack-$run" > "$tmp/pack-$run.json"
  )
done
cmp -- "$tmp/pack-a/pkgre-js-0.1.0.tgz" "$tmp/pack-b/pkgre-js-0.1.0.tgz"
cmp -- "$archive" "$tmp/pack-a/pkgre-js-0.1.0.tgz"

"$indexer/bin/pkgre-js" check "$release/catalog.json" "$release/archives"
"$indexer/bin/pkgre-js" verify "$release/catalog.json" "$release/site-routes"
"$indexer/bin/pkgre-js" verify-monotonic "$release/site-previous" "$release/site-routes"
"$indexer/bin/pkgre-js" verify "$release/catalog.json" "$release/site-final"
"$indexer/bin/pkgre-js" verify-monotonic "$release/site-routes" "$release/site-final"
for run in a b; do
  mkdir "$tmp/render-$run"
  "$indexer/bin/pkgre-js" render-routes "$release/catalog.json" "$release/archives" "$release/site-previous" "$tmp/render-$run/site-routes"
  "$indexer/bin/pkgre-js" render-final "$release/catalog.json" "$tmp/render-$run/site-routes" "$tmp/render-$run/site-final"
done
manifest() {
  (
    cd "$1"
    find . -mindepth 1 -printf '%y %m %P\n' | LC_ALL=C sort
    find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
  )
}
manifest "$release/site-previous" > "$tmp/site-previous.manifest"
manifest "$release/site-routes" > "$tmp/site-routes.manifest"
manifest "$release/site-final" > "$tmp/site-final.manifest"
for run in a b; do
  manifest "$tmp/render-$run/site-routes" > "$tmp/site-routes-$run.manifest"
  manifest "$tmp/render-$run/site-final" > "$tmp/site-final-$run.manifest"
  cmp -- "$tmp/site-routes.manifest" "$tmp/site-routes-$run.manifest"
  cmp -- "$tmp/site-final.manifest" "$tmp/site-final-$run.manifest"
done

printf 'ok bootstrap=js-v0.1.0 tag=%s commit=%s archive=%s catalog=%s\n' "$tag_object" "$commit" "$archive_sha256" "$catalog_sha256"
