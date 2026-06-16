#!/usr/bin/env bash
set -euo pipefail

ADVISOR_DEMO_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ADVISOR_DEMO_HOME}/scripts/lib/common.sh"

bash "${ADVISOR_DEMO_HOME}/scripts/uninstall.sh"

detect_container_cmd 2>/dev/null || true
if [[ -n "${CONTAINER_CMD:-}" ]]; then
  ${CONTAINER_CMD} volume rm git-repositories 2>/dev/null || true
  ${CONTAINER_CMD} network rm "${CONTAINER_NETWORK}" 2>/dev/null || true
  ${CONTAINER_CMD} image rm releases-docker.jfrog.io/jfrog/artifactory-oss:7.117.19 2>/dev/null || true
  ${CONTAINER_CMD} image rm docker.io/library/postgres:16 2>/dev/null || true
  ${CONTAINER_CMD} image rm docker.io/rockstorm/git-server:latest 2>/dev/null || true
fi

rm -f "${ADVISOR_DEMO_HOME}/.envrc"
rm -f "${ADVISOR_DEMO_HOME}/advisor"
rm -f "${ADVISOR_DEMO_HOME}/advisor-cli.tar"

echo "==> Cleanup complete ( ~/.m2 was NOT deleted )"
