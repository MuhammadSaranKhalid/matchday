#!/bin/bash
set -e

# Domain Purity Checker for Match Day
# Ensures no framework or SDK dependencies leak into pure Dart domain packages.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FORBIDDEN_IMPORTS=$(grep -rlE 'package:(flutter|flutter_riverpod|riverpod_annotation|supabase_flutter|supabase|drift|go_router|dio|http)/' lib/features/*/domain lib/core/error 2>/dev/null || true)

if [ -n "$FORBIDDEN_IMPORTS" ]; then
  echo "{\"error\": \"ARCHITECTURE VIOLATION - framework import in pure Dart domain layer: $FORBIDDEN_IMPORTS\"}" >&2
  exit 1
fi

echo "{}"
