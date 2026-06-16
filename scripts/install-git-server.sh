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

ensure_git_server_container() {
  if ${CONTAINER_CMD} ps -a --format '{{.Names}}' | grep -qx git-server; then
    local status
    status="$(${CONTAINER_CMD} inspect -f '{{.State.Status}}' git-server 2>/dev/null || echo missing)"
    if [[ "$status" == "exited" || "$status" == "dead" ]]; then
      echo "    removing failed git-server container"
      ${CONTAINER_CMD} rm -f git-server
    else
      echo "    git-server container already exists — starting if stopped"
      ${CONTAINER_CMD} start git-server 2>/dev/null || true
      return 0
    fi
  fi

  echo "==> Starting local Git server (port 2222)"
  ${CONTAINER_CMD} volume create git-repositories 2>/dev/null || true
  # Do not bind-mount authorized_keys: rockstorm/git-server entrypoint chowns it,
  # which fails on Podman/macOS host file mounts ("Operation not permitted").
  ${CONTAINER_CMD} run --name git-server \
    -d \
    -v git-repositories:/srv/git \
    -p 2222:22 \
    docker.io/rockstorm/git-server:latest
}

configure_git_server_ssh() {
  echo "==> Configuring Git server SSH access"
  ${CONTAINER_CMD} exec -u root git-server sh -c \
    'mkdir -p /home/git/.ssh && chown git:git /home/git/.ssh && chmod 700 /home/git/.ssh'
  ${CONTAINER_CMD} cp "${HOME}/.ssh/id_rsa.pub" git-server:/home/git/.ssh/authorized_keys
  ${CONTAINER_CMD} exec -u root git-server sh -c \
    'chown git:git /home/git/.ssh/authorized_keys && chmod 600 /home/git/.ssh/authorized_keys'
}

wait_for_git_server() {
  local max_wait=120
  local elapsed=0
  while true; do
    local status
    status="$(${CONTAINER_CMD} inspect -f '{{.State.Status}}' git-server 2>/dev/null || echo missing)"
    if [[ "$status" == "exited" || "$status" == "dead" ]]; then
      echo "ERROR: git-server failed to start. Container logs:" >&2
      ${CONTAINER_CMD} logs git-server 2>&1 | tail -20 >&2
      exit 1
    fi
    if [[ "$status" == "running" ]] \
      && ${CONTAINER_CMD} logs git-server 2>&1 | grep -q 'Container configuration completed'; then
      break
    fi
    if (( elapsed >= max_wait )); then
      echo "ERROR: timed out waiting for git-server after ${max_wait}s" >&2
      exit 1
    fi
    echo "    waiting for git-server..."
    sleep 3
    elapsed=$((elapsed + 3))
  done
}

ensure_git_server_container
wait_for_git_server
configure_git_server_ssh

ssh-keyscan -p 2222 localhost >> "${HOME}/.ssh/known_hosts" 2>/dev/null || true

echo "==> Creating bare repository on Git server"
${CONTAINER_CMD} exec -u root git-server rm -rf /srv/git/spring-petclinic-local.git
${CONTAINER_CMD} exec -u git git-server sh -c \
  'mkdir -p /srv/git/spring-petclinic-local.git && git init --bare /srv/git/spring-petclinic-local.git'

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
