#!/usr/bin/env bash
#
# create-release.sh [version] -- tag a release and build its artifact.
#
# With a version argument (1.2.3 or v1.2.3) it uses that. With NO argument it
# shows the current latest release and prompts, defaulting to the next patch
# (X.Y.Z+1) -- press Enter to accept, or type any other version.
#
# Order matters: build.sh derives the version from `git describe`, so the tag
# must exist before the build runs. Steps:
#   1. validate the version and working state (clean tree, tag unused),
#   2. create the annotated tag vX.Y.Z,
#   3. run build.sh (which then sees the exact tag and names the zip cleanly).
#
# Pushing is left to you -- the script prints the command rather than pushing.

set -euo pipefail

cd "$(dirname "$0")"

usage() { echo "usage: $0 [version]   e.g. $0 1.2.3 (or v1.2.3); omit to be prompted" >&2; exit 1; }
valid_version() { echo "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; }

[ $# -le 1 ] || usage

# Fail fast on a dirty tree before asking anything -- a release builds from a
# committed state.
if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty; commit or stash before releasing" >&2
  git status --short >&2
  exit 1
fi

# Latest existing release tag (strict vX.Y.Z), newest first via git's version
# sort (portable; macOS `sort` lacks -V).
latest=$(git tag -l 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || true)

if [ $# -eq 1 ]; then
  version="${1#v}"
else
  # No argument: propose the next patch and prompt.
  if [ -n "$latest" ]; then
    cur="${latest#v}"
    major="${cur%%.*}"; rest="${cur#*.}"
    minor="${rest%%.*}"; patch="${rest##*.}"
    next="$major.$minor.$((patch + 1))"
    echo "Current latest release: $latest"
  else
    next="0.1.0"
    echo "No release tags yet."
  fi
  read -r -p "Version to release [$next]: " version
  version="${version:-$next}"
  version="${version#v}"
fi

if ! valid_version "$version"; then
  echo "error: version must be X.Y.Z (got '$version')" >&2
  exit 1
fi
tag="v$version"

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "error: tag $tag already exists" >&2
  exit 1
fi

echo "tagging $tag ..."
git tag -a "$tag" -m "Release $version"

echo "building artifact ..."
./build.sh

echo
echo "released $tag. push it with:"
echo "  git push origin $tag"
