#!/bin/sh
# Release version consistency: VERSION file == engine app-version ==
# CHANGELOG head section, and (when releasing) the tag too. Family
# pattern (termpilot) minus the package.json leg — Bitsmith has no node
# workspace. Mirrors the release.yml validate logic so the contract runs
# on every push/PR instead of only at tag time. An annotated tag
# v<version> is the only release trigger.
set -eu

cd "$(dirname "$0")/.."

TAG="${1:-}"

# VERSION file: bare semver on a single line, newline-terminated.
grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' VERSION || {
  echo "VERSION must be bare semver (x.y.z)" >&2; exit 1; }
[ "$(tail -c 1 VERSION | wc -l)" -eq 1 ] || {
  echo "VERSION must end with a newline" >&2; exit 1; }
FILE_VERSION=$(cat VERSION)

ENGINE_VERSION=$(sed -n 's/.*(define app-version "\([^"]*\)").*/\1/p' shared/engine/main.rkt)

echo "VERSION=$FILE_VERSION engine=$ENGINE_VERSION tag=${TAG:-none}"

[ -n "$ENGINE_VERSION" ] || { echo "shared/engine/main.rkt has no app-version" >&2; exit 1; }
[ "$FILE_VERSION" = "$ENGINE_VERSION" ] || { echo "VERSION != engine app-version" >&2; exit 1; }

if [ -n "$TAG" ]; then
  [ "${TAG#v}" = "$FILE_VERSION" ] || { echo "tag != VERSION" >&2; exit 1; }
fi

grep -q "^## \[$FILE_VERSION\]" CHANGELOG.md || { echo "CHANGELOG.md has no '## [$FILE_VERSION]' section" >&2; exit 1; }

echo "version-consistency ok"
