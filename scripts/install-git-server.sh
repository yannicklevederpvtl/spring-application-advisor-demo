#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

detect_container_cmd

if ! test -f "${HOME}/.ssh/id_rsa.pub"; then
  echo "==> Generating SSH key for Git server access"
  ssh-keygen -t rsa -N '' -f "${HOME}/.ssh/id_rsa" <<< y
fi

if ${CONTAINER_CMD} ps -a --format '{{.Names}}' | grep -qx git-server; then
  echo "    git-server container already exists — starting if stopped"
  ${CONTAINER_CMD} start git-server 2>/dev/null || true
else
  echo "==> Starting local Git server (port 2222)"
  ${CONTAINER_CMD} volume create git-repositories 2>/dev/null || true
  ${CONTAINER_CMD} run --name git-server \
    -d \
    -v git-repositories:/srv/git \
    -v "${HOME}/.ssh/id_rsa.pub:/home/git/.ssh/authorized_keys:Z" \
    -p 2222:22 \
    docker.io/rockstorm/git-server:latest
fi

until [[ "$(${CONTAINER_CMD} inspect -f '{{.State.Status}}' git-server 2>/dev/null)" == "running" ]]; do
  echo "    waiting for git-server..."
  sleep 3
done

ssh-keyscan -p 2222 localhost >> "${HOME}/.ssh/known_hosts" 2>/dev/null || true

ssh -o StrictHostKeyChecking=accept-new git@localhost -p 2222 \
  "mkdir -p /srv/git/spring-petclinic-local.git && git-init --bare /srv/git/spring-petclinic-local.git" \
  2>/dev/null || ssh git@localhost -p 2222 \
  "mkdir -p /srv/git/spring-petclinic-local.git && git-init --bare /srv/git/spring-petclinic-local.git"

configure_petclinic_git_remote() {
  cd "${ADVISOR_DEMO_HOME}/spring-petclinic"
  if git remote | grep -qx origin; then
    git remote remove origin
  fi
  git remote add origin ssh://git@localhost:2222/srv/git/spring-petclinic-local.git
  git push -u origin advisor-demo
  echo "    spring-petclinic origin → local Git server"
}

configure_petclinic_git_remote
