#!/usr/bin/env bash
set -euo pipefail

ADVISOR_DEMO_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${ADVISOR_DEMO_HOME}/scripts/lib/common.sh"

detect_os
prompt_credentials

echo ""
echo "Select setup mode:"
echo "  1) Minimal — Maven direct to Spring Enterprise (recommended for workshops)"
echo "  2) Enterprise lab — Artifactory OSS mirror (with Postgres)"
echo ""
read -r -p "Choice [1]: " MODE_CHOICE
MODE_CHOICE="${MODE_CHOICE:-1}"

INSTALL_ARTIFACTORY=false
case "$MODE_CHOICE" in
  2) INSTALL_ARTIFACTORY=true ;;
  *) INSTALL_ARTIFACTORY=false ;;
esac

echo ""
read -r -p "Install optional local Git server and point spring-petclinic origin to it? [y/N]: " INSTALL_GIT
INSTALL_GIT="${INSTALL_GIT:-n}"

if [[ "$INSTALL_ARTIFACTORY" == true ]]; then
  detect_container_cmd || exit 1
fi

echo ""
echo "==> Installing Application Advisor CLI ${ADVISOR_VERSION}"
bash "${ADVISOR_DEMO_HOME}/scripts/install-advisor-cli.sh"

echo ""
echo "==> Preparing spring-petclinic sample"
bash "${ADVISOR_DEMO_HOME}/scripts/install-petclinic.sh"

if [[ "$INSTALL_ARTIFACTORY" == true ]]; then
  echo ""
  bash "${ADVISOR_DEMO_HOME}/scripts/install-artifactory.sh"
  bash "${ADVISOR_DEMO_HOME}/scripts/configure-maven-artifactory.sh"
else
  echo ""
  bash "${ADVISOR_DEMO_HOME}/scripts/configure-maven-direct.sh"
fi

if [[ "$INSTALL_GIT" == [Yy]* ]]; then
  echo ""
  bash "${ADVISOR_DEMO_HOME}/scripts/install-git-server.sh"
fi

# Ensure demo env vars in .envrc
if [[ -f "${ADVISOR_DEMO_HOME}/.envrc" ]]; then
  grep -q ADVISOR_DEMO_HOME "${ADVISOR_DEMO_HOME}/.envrc" 2>/dev/null || \
    echo "export ADVISOR_DEMO_HOME=\"${ADVISOR_DEMO_HOME}\"" >> "${ADVISOR_DEMO_HOME}/.envrc"
  grep -q WORKSHOP_ROOT "${ADVISOR_DEMO_HOME}/.envrc" 2>/dev/null || \
    echo 'export WORKSHOP_ROOT="${ADVISOR_DEMO_HOME}"' >> "${ADVISOR_DEMO_HOME}/.envrc"
fi

MODE_NAME=$([[ "$INSTALL_ARTIFACTORY" == true ]] && echo artifactory || echo minimal)
print_summary "$MODE_NAME" "$INSTALL_GIT"
