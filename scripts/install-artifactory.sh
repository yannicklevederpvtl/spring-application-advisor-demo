#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

detect_container_cmd
ensure_jq

cd "${ADVISOR_DEMO_HOME}"

echo "==> Creating container network ${CONTAINER_NETWORK}"
${CONTAINER_CMD} network inspect "${CONTAINER_NETWORK}" >/dev/null 2>&1 \
  || ${CONTAINER_CMD} network create "${CONTAINER_NETWORK}"

if ${CONTAINER_CMD} ps -a --format '{{.Names}}' | grep -qx postgresspringadvisor; then
  echo "    postgres container already exists — starting if stopped"
  ${CONTAINER_CMD} start postgresspringadvisor 2>/dev/null || true
else
  echo "==> Starting PostgreSQL for Artifactory"
  ${CONTAINER_CMD} run --name postgresspringadvisor \
    --network "${CONTAINER_NETWORK}" \
    -d \
    -e POSTGRES_USER=artifactory \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_DB=artifactorydb \
    -p 5432:5432 \
    docker.io/library/postgres:16
  sleep 8
fi

export JFROG_HOME="${ADVISOR_DEMO_HOME}/artifactory"
mkdir -p "${JFROG_HOME}/artifactory/var/etc/"

cat > "${JFROG_HOME}/artifactory/var/etc/system.yaml" <<'EOF'
shared:
  database:
    driver: org.postgresql.Driver
    type: postgresql
    url: jdbc:postgresql://postgresspringadvisor:5432/artifactorydb
    username: artifactory
    password: password
EOF

chmod -R 777 "${JFROG_HOME}/artifactory/var"

echo "==> Extracting Artifactory repository backup"
rm -rf "${ADVISOR_DEMO_HOME}/repoesbackup"
tar -xzf "${ADVISOR_DEMO_HOME}/repoesbackup.zip" -C "${ADVISOR_DEMO_HOME}"

if ${CONTAINER_CMD} ps -a --format '{{.Names}}' | grep -qx artifactory; then
  echo "    artifactory container already exists — starting if stopped"
  ${CONTAINER_CMD} start artifactory 2>/dev/null || true
else
  echo "==> Starting Artifactory OSS"
  ${CONTAINER_CMD} run --name artifactory \
    --network "${CONTAINER_NETWORK}" \
    -v "${ADVISOR_DEMO_HOME}/repoesbackup:/repoesbackup:Z" \
    -v "${JFROG_HOME}/artifactory/var/:/var/opt/jfrog/artifactory:Z" \
    -d \
    -p 8081:8081 \
    -p 8082:8082 \
    releases-docker.jfrog.io/jfrog/artifactory-oss:7.117.19
fi

echo "==> Waiting for Artifactory to become ready (may take several minutes on first start)"
while true; do
  status=$(curl --head -u admin:password http://localhost:8082/artifactory/api/system/ping \
    -o /dev/null -w '%{http_code}' -s 2>/dev/null || echo "000")
  if [[ "$status" == "200" ]]; then
    echo "    Artifactory is ready"
    break
  fi
  echo "    waiting... (HTTP ${status})"
  sleep 15
done

echo "==> Importing pre-configured repositories (Spring Enterprise remote + virtual)"
jq ".remoteRepoConfigs[0].repoTypeConfig.password = \"${REGISTRY_TOKEN}\"" \
  "${ADVISOR_DEMO_HOME}/repoesbackup/artifactory.repository.config.json" > "${ADVISOR_DEMO_HOME}/tmp1.json"
jq ".remoteRepoConfigs[0].repoTypeConfig.username = \"${BROADCOM_ARTIFACTORY_EMAIL}\"" \
  "${ADVISOR_DEMO_HOME}/tmp1.json" > "${ADVISOR_DEMO_HOME}/tmp2.json"
mv "${ADVISOR_DEMO_HOME}/tmp2.json" "${ADVISOR_DEMO_HOME}/repoesbackup/artifactory.repository.config.json"
rm -f "${ADVISOR_DEMO_HOME}/tmp1.json"

curl -sf -u admin:password -X POST http://localhost:8082/artifactory/api/system/decrypt || true
curl -sf -u admin:password \
  -H "Content-Type: application/json" \
  -X POST http://localhost:8082/artifactory/api/import/system \
  --data '{"importPath":"/repoesbackup/","includeMetadata":true,"verbose":true,"failOnError":true,"failIfEmpty":true}'

echo "==> Hydrating ~/.m2 with acme-spring-commons (works with Artifactory mirror)"
"${ADVISOR_DEMO_HOME}/demo/reset-demo.sh" --hydrate-only 2>/dev/null || true

echo "    Artifactory UI: http://localhost:8082/ui/login/  (admin / password)"
