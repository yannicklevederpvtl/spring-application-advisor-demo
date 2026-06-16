#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

echo "==> Configuring Maven (local Artifactory mirror)"
prompt_maven_settings_replace "${ADVISOR_DEMO_HOME}/config/settings-artifactory.xml"
