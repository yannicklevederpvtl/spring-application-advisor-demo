#!/usr/bin/env bash
#
# Reset the Application Advisor "custom upgrades / shared library" demo to a clean,
# reproducible starting state.
#
# Usage:
#   ./demo/reset-demo.sh              # full reset (petclinic + ~/.m2 + inject dependency)
#   ./demo/reset-demo.sh --hydrate-only   # only install acme JARs into ~/.m2

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADVISOR_DEMO_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
export WORKSHOP_ROOT="${ADVISOR_DEMO_HOME}"
PETCLINIC="${ADVISOR_DEMO_HOME}/spring-petclinic"
LOCAL_REPO="${SCRIPT_DIR}/local-repo"
MAPPING_FILE="${SCRIPT_DIR}/mappings/acme-spring-commons.json"
PINNED_COMMIT="9ecdc1111e3da388a750ace41a125287d9620534"
ARTIFACT_BASE="${LOCAL_REPO}/com/acme/acme-spring-commons"
HYDRATE_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --hydrate-only) HYDRATE_ONLY=true ;;
  esac
done

hydrate_m2() {
  echo "==> Hydrate ~/.m2 with shared-library artifacts from local-repo"
  for v in 1.0.0 2.0.0 3.0.0; do
    mvn -q org.apache.maven.plugins:maven-install-plugin:install-file \
      -Dfile="${ARTIFACT_BASE}/${v}/acme-spring-commons-${v}.jar" \
      -DpomFile="${ARTIFACT_BASE}/${v}/acme-spring-commons-${v}.pom"
    echo "    installed com.acme:acme-spring-commons:${v}"
  done
}

if [[ "$HYDRATE_ONLY" == true ]]; then
  hydrate_m2
  exit 0
fi

echo "==> 1/3 Reset spring-petclinic to pinned commit (${PINNED_COMMIT})"
if [[ ! -d "${PETCLINIC}/.git" ]]; then
  echo "ERROR: ${PETCLINIC} is not a git checkout. Run ./install.sh first." >&2
  exit 1
fi
cd "${PETCLINIC}"
git checkout -f -B advisor-demo "${PINNED_COMMIT}"
git clean -fdx

hydrate_m2

echo "==> 3/3 Inject acme-spring-commons:1.0.0 into petclinic pom.xml (idempotent)"
cd "${PETCLINIC}"
if grep -q "acme-spring-commons" pom.xml; then
  echo "    already present, skipping"
else
  awk '/<\/dependencies>/ && !done {
        print "    <!-- Internal shared library (demo): blocks Boot 3 upgrade until mapped -->";
        print "    <dependency>";
        print "      <groupId>com.acme</groupId>";
        print "      <artifactId>acme-spring-commons</artifactId>";
        print "      <version>1.0.0</version>";
        print "    </dependency>";
        done=1
      }
      { print }' pom.xml > pom.xml.tmp && mv pom.xml.tmp pom.xml
  echo "    injected"
fi

cat <<EOF

==> Demo ready. Suggested flow:

  export ADVISOR_DEMO_HOME="${ADVISOR_DEMO_HOME}"
  export WORKSHOP_ROOT="\${ADVISOR_DEMO_HOME}"
  cd "${PETCLINIC}"

  # (a) WITHOUT the mapping: Advisor is blocked by the unmapped internal library
  unset SPRING_ADVISOR_MAPPING_CUSTOM_0_FILEPATH
  advisor build-config get
  advisor upgrade-plan get

  # (b) WITH the mapping: Advisor plans the shared-lib bump (1.0.0 -> 2.0.0 -> 3.0.0)
  export SPRING_ADVISOR_MAPPING_CUSTOM_0_FILEPATH="${MAPPING_FILE}"
  advisor upgrade-plan get
  advisor upgrade-plan apply
  git diff

  # (c) Verify green build on JDK 17
  sdk use java 17.0.13-tem
  ./mvnw test

EOF
echo "==> Done."
