# Demo 2 — Custom upgrades for internal shared libraries

Shows how Application Advisor handles an **internal shared library** (`com.acme:acme-spring-commons`) that blocks a Spring Boot upgrade until a **custom upgrade mapping** is provided.

**Audience:** Same pinned `spring-petclinic` as [Demo 1](DEMO-1-upgrade-boot.md). Demo 2 focuses on the **mapping** story. After the mapping unblocks the plan, you still complete Boot 2.7 → 4.0 with Demo 1’s **incremental apply loop** (one step at a time).

Official reference: [Configure upgrade mappings for internal shared libraries](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/application-advisor/1-6/app-advisor/custom-upgrades.html)

## Assets

| Path | Purpose |
|---|---|
| `demo/acme-spring-commons/` | Source + POMs for library versions 1.0.0 / 2.0.0 / 3.0.0 |
| `demo/local-repo/` | Pre-built JARs (offline, committed) |
| `demo/mappings/acme-spring-commons.json` | Custom upgrade mapping (CLI 1.6 full format) |
| `demo/reset-demo.sh` | Reset petclinic + hydrate `~/.m2` + inject dependency |

## Library upgrade chain

| Line | Java | Spring Boot | Resolves to |
|---|---|---|---|
| `1.0.x` | 8 | 2.7.x | `1.0.0` (injected into petclinic) |
| `2.0.x` | 17 | 3.2.x | `2.0.0` |
| `3.0.x` | 17 | 4.0.x | `3.0.0` |

## Reset to a clean demo state

```bash
export ADVISOR_DEMO_HOME="$(pwd)"
export WORKSHOP_ROOT="${ADVISOR_DEMO_HOME}"
./demo/reset-demo.sh
cd spring-petclinic
```

## Demo flow

### (a) Without mapping — upgrade blocked

```bash
unset SPRING_ADVISOR_MAPPING_CUSTOM_0_FILEPATH
advisor build-config get
advisor upgrade-plan get
```

Advisor detects the unmapped internal library and limits the upgrade plan.

### (b) With mapping — shared lib bump planned

```bash
export SPRING_ADVISOR_MAPPING_CUSTOM_0_FILEPATH="${ADVISOR_DEMO_HOME}/demo/mappings/acme-spring-commons.json"
advisor upgrade-plan get
advisor upgrade-plan apply
git diff    # first step: acme-spring-commons + Boot changes (plan may not be complete yet)
```

### (c) Finish the Boot upgrade (same as Demo 1)

The mapping unblocks planning for `acme-spring-commons`. You still apply the upgrade **one step at a time** — switch JDKs, test, and commit between steps.

Follow the [Demo 1 incremental upgrade loop](DEMO-1-upgrade-boot.md#incremental-upgrade-loop), especially:

- [Java 8 → 11](DEMO-1-upgrade-boot.md#java-8--11)
- [Java 11 → 17](DEMO-1-upgrade-boot.md#java-11--17)
- [Spring Boot 2.7 → 4.0 (multiple steps)](DEMO-1-upgrade-boot.md#spring-boot-27--40-multiple-steps)

Repeat until `advisor upgrade-plan get` shows no further steps:

```bash
advisor build-config get && advisor upgrade-plan apply
git diff
./mvnw spring-javaformat:apply   # if format validation fails
sdk use java 17.0.13-tem
./mvnw test
git add -A && git commit -m "Apply next upgrade step"
```

### (d) Verify

```bash
sdk use java 17.0.13-tem
./mvnw spring-javaformat:apply   # if needed
./mvnw test
./mvnw spring-boot:run           # http://localhost:8080
```

## Regenerate mapping (optional)

On your machine with Advisor CLI:

```bash
cd demo/acme-spring-commons
advisor mapping create -c com.acme:acme-spring-commons
# copy output from .advisor/mappings/ to demo/mappings/
```
