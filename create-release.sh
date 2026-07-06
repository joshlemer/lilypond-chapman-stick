#!/usr/bin/env bash
#
# create-release.sh vX.Y.Z -- tag a release and build its artifact.
#
# Order matters: build.sh derives the version from `git describe`, so the tag
# must exist before the build runs. Steps:
#   1. validate the version and working state (clean tree, tag unused),
#   2. create the annotated tag vX.Y.Z,
#   3. run build.sh (which now sees the exact tag and names the zip cleanly).
#
# Pushing is left to you -- the script prints the command rather than pushing.

set -euo pipefail

cd "$(dirname "$0")"

usage() { echo "usage: $0 <version>   e.g. $0 1.0.0  (or v1.0.0)" >&2; exit 1; }

[ $# -eq 1 ] || usage

# Accept 1.0.0 or v1.0.0; normalize to a bare version and a vX.Y.Z tag.
version="${1#v}"
if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "error: version must be X.Y.Z (got '$1')" >&2
  usage
fi
tag="v$version"

# Preconditions: committed, and the tag isn't taken.
if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty; commit or stash before releasing" >&2
  git status --short >&2
  exit 1
fi
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
