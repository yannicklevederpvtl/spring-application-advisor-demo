#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

detect_os

install_advisor_cli() {
  local url base="${ADVISOR_DEMO_HOME}"
  url="https://packages.broadcom.com/artifactory/spring-enterprise/com/vmware/tanzu/spring/${ADVISOR_CLI_ARTIFACT}/${ADVISOR_VERSION}/${ADVISOR_CLI_ARTIFACT}-${ADVISOR_VERSION}.tar"

  if command -v advisor >/dev/null 2>&1; then
    printf 'Advisor CLI already installed (%s). Replace with %s (y/n)? ' "$(advisor -v 2>/dev/null | head -1 || echo unknown)" "${ADVISOR_VERSION}"
    read -r answer
    if [[ "$answer" != [Yy]* ]]; then
      echo "    keeping existing advisor CLI"
      return 0
    fi
  fi

  echo "==> Downloading Application Advisor CLI ${ADVISOR_VERSION} (${ADVISOR_CLI_ARTIFACT})"
  curl -fsSL -H "Authorization: Bearer ${REGISTRY_TOKEN}" \
    -o "${base}/advisor-cli.tar" \
    "${url}"

  tar -xf "${base}/advisor-cli.tar" -C "${base}" --strip-components=1 --exclude=./META-INF

  echo "==> Installing advisor to /usr/local/bin (sudo required)"
  sudo install -m 755 "${base}/advisor" /usr/local/bin/advisor
  advisor -v
}

install_advisor_cli
