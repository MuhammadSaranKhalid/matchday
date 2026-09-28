#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

fail() {
  printf 'repository boundary violation: %s\n' "$1" >&2
  exit 1
}

required_paths=(
  app/pubspec.yaml
  app/lib/main.dart
  app/test/architecture_test.dart
  app/android
  app/ios
  app/web
  app/linux
  app/macos
  app/windows
  backend/package.json
  backend/apps/api
  backend/apps/worker
  backend/libs/platform
  backend/test/unit
  backend/test/architecture
  backend/test/e2e
  supabase/config.toml
  website/package.json
  media-worker/package.json
)

for path in "${required_paths[@]}"; do
  [[ -e "$repository_root/$path" ]] || fail "missing $path"
done

forbidden_root_paths=(
  pubspec.yaml
  lib
  test
  assets
  android
  ios
  web
  linux
  macos
  windows
  package.json
  apps
  libs
  Dockerfile
  docker-compose.yml
)

for path in "${forbidden_root_paths[@]}"; do
  [[ ! -e "$repository_root/$path" ]] || fail "root still owns $path"
done

ignored_paths=(
  .dart_tool/probe
  build/probe
  node_modules/probe
  dist/probe
  app/.dart_tool/probe
  app/build/probe
  backend/node_modules/probe
  backend/dist/probe
)

for path in "${ignored_paths[@]}"; do
  git -C "$repository_root" check-ignore -q "$path" || fail "$path is not ignored"
done
