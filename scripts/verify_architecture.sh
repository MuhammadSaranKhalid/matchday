#!/bin/bash
set -eo pipefail

# Match Day Architecture & Quality Gate Verification Script
# Enforces the Clean Architecture invariants defined in .agents/rules/

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "=================================================="
echo "  Match Day Quality Gates & Architecture Audit   "
echo "=================================================="

# 1. Pure Dart Domain Purity Check
echo ""
echo "▶ Gate 1: Checking Domain Layer Purity (Pure Dart)..."
FORBIDDEN_IMPORTS=$(grep -rlE 'package:(flutter|flutter_riverpod|riverpod_annotation|supabase_flutter|supabase|drift|go_router|dio|http)/' lib/features/*/domain lib/core/error 2>/dev/null || true)

if [ -n "$FORBIDDEN_IMPORTS" ]; then
  echo "❌ CRITICAL ARCHITECTURAL VIOLATION: Framework/SDK imports found in pure Dart Domain layer!"
  echo "Offending files:"
  echo "$FORBIDDEN_IMPORTS"
  exit 1
fi
echo "✅ Gate 1 Passed: Domain layer is 100% pure Dart."

# 2. No Use-Case Layer Check
echo ""
echo "▶ Gate 2: Verifying No Use-Case Layer..."
USE_CASES=$(find lib/features/*/domain/usecases lib/core/usecase -type f 2>/dev/null || true)
if [ -n "$USE_CASES" ]; then
  echo "❌ CRITICAL ARCHITECTURAL VIOLATION: Use-case layer detected! (Forbidden since 2026-05-29)"
  echo "Offending files:"
  echo "$USE_CASES"
  exit 1
fi
echo "✅ Gate 2 Passed: No use-case layer present."

# 3. Architecture Unit Tests
echo ""
echo "▶ Gate 3: Running test/architecture_test.dart..."
flutter test test/architecture_test.dart
echo "✅ Gate 3 Passed: All architectural boundary tests passed."

# 4. Static Analysis on lib/
echo ""
echo "▶ Gate 4: Running flutter analyze lib/..."
flutter analyze lib/
echo "✅ Gate 4 Passed: Zero static analysis issues in lib/."

echo ""
echo "=================================================="
echo "🎉 ALL MATCH DAY ARCHITECTURAL QUALITY GATES PASSED!"
echo "=================================================="
exit 0
