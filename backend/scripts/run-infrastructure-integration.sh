#!/usr/bin/env bash
set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backend_directory="$(cd "${script_directory}/.." && pwd)"
compose_file="${backend_directory}/test/integration/docker-compose.yml"
project_name="matchday-infra-${PPID}-$(date +%s)-${RANDOM}"
test_target=""

while (($# > 0)); do
  case "$1" in
    --test)
      test_target="${2:?--test requires a filename}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

cleanup() {
  docker compose -p "${project_name}" -f "${compose_file}" down --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

docker compose -p "${project_name}" -f "${compose_file}" up -d --wait
postgres_address="$(docker compose -p "${project_name}" -f "${compose_file}" port postgres 5432)"
redis_address="$(docker compose -p "${project_name}" -f "${compose_file}" port redis 6379)"
postgres_port="${postgres_address##*:}"
redis_port="${redis_address##*:}"

export NODE_ENV=test
export DATABASE_URL="postgresql://postgres:matchday_test_password@127.0.0.1:${postgres_port}/matchday_test"
export REDIS_URL="redis://127.0.0.1:${redis_port}"

cd "${backend_directory}"
if [[ -n "${test_target}" ]]; then
  if [[ "${test_target}" == */* ]]; then
    echo "--test accepts a filename only" >&2
    exit 2
  fi
  test_path="$(find test/integration -type f -name "${test_target}" -print -quit)"
  if [[ -z "${test_path}" ]]; then
    echo "Integration test not found: ${test_target}" >&2
    exit 2
  fi
  corepack pnpm vitest run "${test_path}"
else
  corepack pnpm vitest run test/integration
fi
