#!/usr/bin/env bash
#
# build.sh -- bundle everything in src/ into a versioned zip under out/.
#
# The version is the canonical git tag, read via `git describe`. Tag releases
# as `vX.Y.Z` (e.g. `git tag v1.0.0`). Builds from an exact tag get a clean
# version (1.0.0); anything else gets a descriptive dev version
# (1.0.0-3-gabc1234, or 0.0.0-g<sha> before the first tag) so release and
# work-in-progress artifacts never collide.

set -euo pipefail

cd "$(dirname "$0")"

name="lilypond-chapman-stick"
src="src"
out="out"

# Canonical version = git tag. --dirty flags an uncommitted tree; --always
# falls back to a bare sha, which we normalize to a 0.0.0 dev version below.
raw=$(git describe --tags --always --dirty 2>/dev/null || echo "")
if [ -z "$raw" ]; then
  echo "error: not a git repo (or git unavailable); cannot determine version" >&2
  exit 1
fi

case "$raw" in
  v*) version="${raw#v}" ;;            # tagged: strip the leading v
  *)  version="0.0.0-g$raw" ;;         # no tag yet: sha-based dev version
esac

stem="$name-$version"          # e.g. lilypond-chapman-stick-1.0.0
zip_name="$stem.zip"

mkdir -p "$out"
rm -f "$out/$zip_name"
rm -rf "$out/$stem"

# Stage src/ under a top-level directory named after the archive, so unzipping
# yields  $stem/<files>  rather than dumping files into the current directory.
cp -R "$src" "$out/$stem"
( cd "$out" && zip -r -q "$zip_name" "$stem" )
rm -rf "$out/$stem"

echo "built $out/$zip_name"
