#!/usr/bin/env bash
# Fetch a pull request's head as data.
#
# Creates a bare repository candidate.git and, from the head's tree, the
# worktree candidate/, both below $GITHUB_WORKSPACE. Refuses a head that does
# not contain the commit whose checks run, and a tree that holds a symbolic
# link, a submodule or a .gitattributes, before the worktree exists. Nothing
# from the tree is run: it is written out with no hook, no system or global Git
# configuration, no attribute file and no transport but HTTPS.
#
# Reads from the environment, as GitHub Actions sets it:
#   GITHUB_REPOSITORY     the base repository, owner/name
#   GITHUB_SHA            the commit of the default branch whose workflow runs
#   HEAD_SHA              the commit at the head of the pull request
#   PULL_REQUEST_NUMBER   the number of the pull request
#   GITHUB_WORKSPACE      the directory that receives candidate.git and candidate/
set -euo pipefail

# Git derives the modes of the written tree from the umask; the checks compare
# them, and expect directories 755 and files 644.
umask 022

refuse() {
  printf '%s: %q\n' "$1" "$2" >&2
  exit 1
}

: "${GITHUB_REPOSITORY:?}" "${GITHUB_SHA:?}" "${HEAD_SHA:?}" "${PULL_REQUEST_NUMBER:?}"
workspace="${GITHUB_WORKSPACE:-$PWD}"

[[ "$GITHUB_SHA" =~ ^[0-9a-f]{40}$ ]] || refuse 'the accepted commit is not a commit hash' "$GITHUB_SHA"
[[ "$HEAD_SHA" =~ ^[0-9a-f]{40}$ ]] || refuse "the pull request's head is not a commit hash" "$HEAD_SHA"
[[ "$PULL_REQUEST_NUMBER" =~ ^[1-9][0-9]{0,8}$ ]] || refuse 'the pull request number is not a number' "$PULL_REQUEST_NUMBER"

repository="$workspace/candidate.git"
candidate="$workspace/candidate"
[[ ! -e "$repository" && ! -L "$repository" ]] || refuse 'the candidate repository already exists' "$repository"
[[ ! -e "$candidate" && ! -L "$candidate" ]] || refuse 'the candidate tree already exists' "$candidate"

# Every Git command on the candidate runs with no hook, no system or global
# configuration, no attribute file and no transport but HTTPS, as the packaging
# of pkgre/pkgre does.
git_candidate() {
  GIT_TERMINAL_PROMPT=0 GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    GIT_ATTR_NOSYSTEM=1 \
    git -c core.hooksPath=/dev/null \
      -c core.attributesFile=/dev/null \
      -c protocol.allow=never \
      -c protocol.https.allow=always \
      "$@"
}

git_candidate init --quiet --bare "$repository"
remote="https://github.com/$GITHUB_REPOSITORY.git"
printf 'fetching %s\n' "$remote"
git_candidate -C "$repository" config remote.origin.url "$remote"
git_candidate -C "$repository" config remote.origin.promisor true
git_candidate -C "$repository" config remote.origin.partialclonefilter blob:none

fetch() {
  git_candidate -C "$repository" fetch --quiet --no-tags --filter=blob:none origin "$1"
}

# The base repository serves every pull request's head by its commit hash; when
# it does not, the pull request's head ref must hold the same commit.
if ! fetch "$HEAD_SHA"; then
  fetch "refs/pull/$PULL_REQUEST_NUMBER/head:refs/pull/$PULL_REQUEST_NUMBER/head"
  fetched="$(git_candidate -C "$repository" rev-parse --verify --quiet "refs/pull/$PULL_REQUEST_NUMBER/head^{commit}" || true)"
  [[ "$fetched" = "$HEAD_SHA" ]] ||
    refuse "refs/pull/$PULL_REQUEST_NUMBER/head is not the pull request's head" "${fetched:-none}"
fi
fetch "$GITHUB_SHA"

if ! git_candidate -C "$repository" merge-base --is-ancestor "$GITHUB_SHA" "$HEAD_SHA"; then
  echo "the pull request is not up to date with main at $GITHUB_SHA; update it" >&2
  exit 1
fi

listing="$(mktemp)"
trap 'rm -f -- "$listing"' EXIT
git_candidate -C "$repository" ls-tree -r -z --full-tree "$HEAD_SHA" > "$listing"

while IFS= read -r -d '' record; do
  metadata="${record%%$'\t'*}"
  path="${record#*$'\t'}"
  mode="${metadata%% *}"
  case "$mode" in
    100644 | 100755) ;;
    120000) refuse 'the pull request holds a symbolic link' "$path" ;;
    160000) refuse 'the pull request holds a submodule' "$path" ;;
    *) refuse "the pull request holds an entry of mode $mode" "$path" ;;
  esac
  [[ "${path##*/}" != .gitattributes ]] || refuse 'the pull request holds an attribute file' "$path"
done < "$listing"

git_candidate -C "$repository" worktree add --quiet --detach "$candidate" "$HEAD_SHA"

printf 'candidate head=%s tree=%s\n' "$HEAD_SHA" \
  "$(git_candidate -C "$repository" rev-parse --verify "$HEAD_SHA^{tree}")"
