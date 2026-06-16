#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

install_petclinic() {
  cd "${ADVISOR_DEMO_HOME}"
  if [[ -d spring-petclinic/.git ]]; then
    echo "==> spring-petclinic already cloned — refreshing branch advisor-demo"
    cd spring-petclinic
    git fetch origin 2>/dev/null || true
  else
    echo "==> Cloning spring-petclinic"
    git clone https://github.com/spring-projects/spring-petclinic
    cd spring-petclinic
  fi
  git checkout -f -B advisor-demo "${PETCLINIC_PINNED_COMMIT}"
  echo "    pinned at ${PETCLINIC_PINNED_COMMIT}"
}

install_petclinic
