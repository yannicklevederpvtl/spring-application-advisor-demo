#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

echo "==> Configuring Maven (direct Spring Enterprise access)"
prompt_maven_settings_replace "${ADVISOR_DEMO_HOME}/config/settings-maven-direct.xml.template"
