# Demo 1 — Upgrade Spring Boot 2.7 to 4.0

Step-by-step upgrade of [spring-petclinic](https://github.com/spring-projects/spring-petclinic) using Application Advisor **1.6.3**.

Official reference: [How to upgrade Spring Boot from 2.7 to 4.0](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/application-advisor/1-6/app-advisor/how-to-guides-upgrade-boot.html)

## Prerequisites

- Application Advisor CLI 1.6.3 in your `PATH` (`advisor -v`)
- JDK **8, 11, and 17** (SDKMAN recommended)
- Maven configured for Spring Enterprise (`~/.m2/settings.xml` from install)

## Sample project

After `./install.sh`, `spring-petclinic` is pinned at commit `9ecdc111…` on branch `advisor-demo` (Boot 2.7.3 / Java 8).

```bash
cd spring-petclinic
advisor build-config get
advisor upgrade-plan get
```

## Incremental upgrade loop

Apply **one step at a time**, verify, commit:

```bash
advisor upgrade-plan apply
git diff
```

### Java 8 → 11

```bash
sdk use java 11.0.25-tem
./mvnw test
git add -A && git commit -m "Upgrade java from 8 to 11"
```

### Java 11 → 17

```bash
advisor build-config get && advisor upgrade-plan apply
sdk use java 17.0.13-tem
./mvnw test
git add -A && git commit -m "Upgrade java from 11 to 17"
```

### Spring Boot 2.7 → 4.0 (multiple steps)

Repeat until the plan is complete:

```bash
advisor build-config get && advisor upgrade-plan apply
git diff
./mvnw spring-javaformat:apply   # if format validation fails
sdk use java 17.0.13-tem
./mvnw test
git add -A && git commit -m "Apply next upgrade step"
```

## Run the application

```bash
sdk use java 17.0.13-tem
./mvnw spring-boot:run
```

Open http://localhost:8080

## Troubleshooting

- **spring-javaformat failures** after upgrade: `./mvnw spring-javaformat:apply`
- **Checkstyle / NoHttp errors** from a previous run: see [Advisor troubleshooting](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/application-advisor/1-6/app-advisor/how-to-guides-upgrade-boot.html)
