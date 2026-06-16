#!/usr/bin/env bash
# Shared helpers for spring-application-advisor-demo install scripts.

set -euo pipefail

ADVISOR_DEMO_HOME="${ADVISOR_DEMO_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
ADVISOR_VERSION="${ADVISOR_VERSION:-1.6.3}"
PETCLINIC_PINNED_COMMIT="${PETCLINIC_PINNED_COMMIT:-9ecdc1111e3da388a750ace41a125287d9620534}"
CONTAINER_NETWORK="${CONTAINER_NETWORK:-advisor-demo-net}"

export ADVISOR_DEMO_HOME ADVISOR_VERSION PETCLINIC_PINNED_COMMIT

# Prefer podman when available, fall back to docker.
detect_container_cmd() {
  if command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD=podman
  elif command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD=docker
  else
    echo "ERROR: Neither docker nor podman found. Required for Enterprise lab mode." >&2
    return 1
  fi
  export CONTAINER_CMD
}

detect_os() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "${os}-${arch}" in
    Darwin-arm64|Darwin-aarch64)
      ADVISOR_CLI_ARTIFACT="application-advisor-cli-macos-arm64"
      ;;
    Darwin-x86_64)
      ADVISOR_CLI_ARTIFACT="application-advisor-cli-macos"
      ;;
    Linux-*)
      ADVISOR_CLI_ARTIFACT="application-advisor-cli-linux"
      ;;
    *)
      echo "ERROR: Unsupported OS (${os} ${arch}). This demo supports macOS and Linux only." >&2
      echo "       See README.md → Windows users for manual setup." >&2
      exit 1
      ;;
  esac
  export ADVISOR_CLI_ARTIFACT
}

ensure_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  echo "ERROR: 'jq' is required for Enterprise lab mode." >&2
  echo "  macOS: brew install jq" >&2
  echo "  Linux: use your package manager (e.g. apt install jq)" >&2
  exit 1
}

prompt_credentials() {
  if [[ -z "${BROADCOM_ARTIFACTORY_EMAIL:-}" ]]; then
    read -r -p "Broadcom Support Portal email: " BROADCOM_ARTIFACTORY_EMAIL
  fi
  if [[ -z "${REGISTRY_TOKEN:-}" && -z "${BROADCOM_ARTIFACTORY_TOKEN:-}" ]]; then
    read -r -s -p "Registry token (Broadcom Support Portal): " REGISTRY_TOKEN
    echo ""
  fi
  REGISTRY_TOKEN="${REGISTRY_TOKEN:-${BROADCOM_ARTIFACTORY_TOKEN:-}}"
  export BROADCOM_ARTIFACTORY_EMAIL REGISTRY_TOKEN BROADCOM_ARTIFACTORY_TOKEN="$REGISTRY_TOKEN"

  if [[ ! -f "${ADVISOR_DEMO_HOME}/.envrc" ]]; then
    printf 'Save credentials to .envrc in this directory (y/n)? '
    read -r answer
    if [[ "$answer" == [Yy]* ]]; then
      cat > "${ADVISOR_DEMO_HOME}/.envrc" <<EOF
export ADVISOR_DEMO_HOME="${ADVISOR_DEMO_HOME}"
export WORKSHOP_ROOT="\${ADVISOR_DEMO_HOME}"
export BROADCOM_ARTIFACTORY_EMAIL="${BROADCOM_ARTIFACTORY_EMAIL}"
export REGISTRY_TOKEN="${REGISTRY_TOKEN}"
export BROADCOM_ARTIFACTORY_TOKEN="${REGISTRY_TOKEN}"
EOF
      if command -v direnv >/dev/null 2>&1; then
        direnv allow "${ADVISOR_DEMO_HOME}" || true
      fi
    fi
  fi
}

prompt_maven_settings_replace() {
  local template="$1"
  local dest="${HOME}/.m2/settings.xml"
  mkdir -p "${HOME}/.m2"
  if [[ -f "$dest" ]]; then
    printf 'Replace existing ~/.m2/settings.xml (backup recommended) (y/n)? '
    read -r answer
    if [[ "$answer" != [Yy]* ]]; then
      echo "    kept existing ~/.m2/settings.xml"
      return 0
    fi
  fi
  cp "$template" "$dest"
  echo "    installed ${dest}"
}

print_color() {
  local color="$1"
  shift
  printf '\033[%sm%s\033[0m\n' "$color" "$*"
}

print_summary() {
  local mode="$1"
  local git_server="${2:-n}"
  echo ""
  print_color "01;34" "=== Setup complete ==="
  echo "Demo home: ${ADVISOR_DEMO_HOME}"
  echo "Mode: ${mode}"
  echo ""
  print_color "01;34" "Environment"
  echo "  export ADVISOR_DEMO_HOME=\"${ADVISOR_DEMO_HOME}\""
  echo "  export WORKSHOP_ROOT=\"\${ADVISOR_DEMO_HOME}\""
  echo ""
  print_color "01;34" "Demo 1 — Upgrade Spring Boot 2.7 → 4.0"
  echo "  cd spring-petclinic"
  echo "  advisor build-config get"
  echo "  advisor upgrade-plan get"
  echo "  advisor upgrade-plan apply"
  echo ""
  print_color "01;34" "Demo 2 — Custom upgrades (acme-spring-commons)"
  echo "  ./demo/reset-demo.sh"
  echo "  export SPRING_ADVISOR_MAPPING_CUSTOM_0_FILEPATH=\"\${ADVISOR_DEMO_HOME}/demo/mappings/acme-spring-commons.json\""
  echo ""
  if [[ "$mode" == "artifactory" ]]; then
    print_color "01;34" "Artifactory UI"
    echo "  http://localhost:8082/ui/login/  (admin / password)"
  fi
  if [[ "$git_server" == [Yy]* ]]; then
    print_color "01;34" "Git server"
    echo "  ssh://git@localhost:2222/srv/git/spring-petclinic-local.git"
  fi
  echo ""
  echo "Docs: docs/DEMO-1-upgrade-boot.md  docs/DEMO-2-custom-upgrades.md"
  echo "MCP:  docs/MCP_CONFIGURATION_GUIDE.md"
}
