#!/usr/bin/env bash
set -euo pipefail

ADVISOR_DEMO_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ADVISOR_DEMO_HOME}/scripts/lib/common.sh"

detect_container_cmd 2>/dev/null || CONTAINER_CMD=""

stop_rm() {
  local name="$1"
  if [[ -n "$CONTAINER_CMD" ]] && ${CONTAINER_CMD} ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$name"; then
    ${CONTAINER_CMD} stop "$name" 2>/dev/null || true
    ${CONTAINER_CMD} rm -f "$name" 2>/dev/null || true
    echo "    removed container ${name}"
  fi
}

echo "==> Stopping demo containers"
stop_rm git-server
stop_rm artifactory
stop_rm postgresspringadvisor

echo "==> Removing demo directories"
rm -rf "${ADVISOR_DEMO_HOME}/artifactory"
rm -rf "${ADVISOR_DEMO_HOME}/repoesbackup"
rm -rf "${ADVISOR_DEMO_HOME}/spring-petclinic"

echo "==> Done. Advisor CLI and ~/.m2 were NOT removed."
echo "    Run scripts/cleanup.sh for a deeper clean."
