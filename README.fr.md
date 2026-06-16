# Démo Spring Application Advisor

Démo locale pour **[Application Advisor 1.6.3](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/application-advisor/1-6/app-advisor/index.html)** — mise à niveau de **Spring Petclinic** (Boot 2.7 → 4.0) et **mappings de montée de version** pour bibliothèques internes.

🇬🇧 [English version](README.md)

## Contenu

| Démo | Description | Guide |
|---|---|---|
| **Démo 1** | Montée Boot 2.7 → 4.0 | [docs/DEMO-1-upgrade-boot.md](docs/DEMO-1-upgrade-boot.md) |
| **Démo 2** | Bibliothèque `acme-spring-commons` + mapping personnalisé | [docs/DEMO-2-custom-upgrades.md](docs/DEMO-2-custom-upgrades.md) |
| **MCP** | Intégration IDE via `advisor mcp` (sans serveur) | [docs/MCP_CONFIGURATION_GUIDE.md](docs/MCP_CONFIGURATION_GUIDE.md) |

Guides officiels : [Application Advisor how-to guides](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/application-advisor/1-6/app-advisor/app-advisor-examples.html)

## Prérequis

- **macOS ou Linux** (détection automatique)
- Capacité de **créer et activer un compte** sur le [Broadcom Support Portal](https://support.broadcom.com) et d’obtenir un **Registry Token**
- Entitlement actif : **Tanzu Spring** ou **Tanzu Platform**
- **JDK 17+** minimum pour le CLI Advisor ; **JDK 8, 11 et 17** recommandés pour la montée de version
- **Git**, **curl**, **Maven** (ou `./mvnw` dans petclinic)
- **Mode lab entreprise uniquement :** Docker, Podman ou autre moteur de conteneurs compatible OCI (détection automatique)

### Accès aux dépôts Maven

- **Mode minimal :** Maven Central + dépôt Spring Enterprise (`packages.broadcom.com`) **en direct**, ou **miroir interne** configuré par votre équipe plateforme — adaptez l’URL et les identifiants dans `~/.m2/settings.xml`.
- **Mode lab entreprise :** Artifactory OSS local qui proxifie Spring Enterprise.

En cas de doute, contactez votre **administrateur de dépôt d’artefacts** avant l’atelier.

## Démarrage rapide

```bash
git clone <ce-repo>
cd spring-application-advisor-demo
./install.sh
```

Menu interactif :

1. **Minimal** (recommandé) — Maven direct vers Spring Enterprise ; sans conteneurs
2. **Lab entreprise** — miroir Artifactory OSS (avec Postgres)
3. **Optionnel :** serveur Git local (reconfigure l’`origin` de `spring-petclinic` pour des démos `git push`)

Les identifiants peuvent être enregistrés dans `.envrc` (voir `.envrc.example`). **Ne commitez jamais de tokens.**

## Architecture

Deux modes d’installation — le même **CLI Application Advisor**, topologies Maven différentes. Aucun serveur Application Advisor dans les deux cas.

### Mode minimal (recommandé)

![Mode minimal — CLI, fichiers de mapping, Maven Central, Spring Enterprise, dépôt local](assets/spring-advisor-demo-minimal.svg)

Le **CLI Spring Application Advisor** lit les **fichiers de mapping** (recettes OpenRewrite ↔ projets Spring) dans `demo/mappings/` — par exemple `acme-spring-commons.json` pour la Démo 2.

Maven résout les artefacts directement depuis **Maven Central** et le **dépôt Spring Enterprise** ; les dépendances sont mises en cache dans le **maven-local-repo** (`~/.m2`, plus `demo/local-repo/` pour les JARs `acme-spring-commons` hors ligne).

### Lab entreprise (optionnel)

![Lab entreprise — CLI, mappings, Git, Artifactory, dépôts amont](assets/spring-advisor-demo-enterprise-lab.svg)

Même flux CLI et **fichiers de mapping**. Maven pointe vers un **miroir Artifactory OSS** local (avec Postgres ; dépôts préconfigurés via `repoesbackup.zip`) :

| Dépôt Artifactory | Rôle |
|---|---|
| `maven-virtual-repo` | URL Maven unique dans `settings.xml` |
| `maven-remote-repo` | Proxifie **Maven Central** |
| `spring-enterprise-mvn-remote` | Proxifie le **dépôt Spring Enterprise** |
| `maven-local-repo` | Artefacts mis en cache sur le miroir |

Un **dépôt Git** local optionnel (menu d’installation, option 3) permet de démontrer un `git push` après `advisor upgrade-plan apply`.

### Démo 1 — Montée Boot

```bash
cd spring-petclinic
advisor build-config get
advisor upgrade-plan get
advisor upgrade-plan apply
git diff
```

Voir [docs/DEMO-1-upgrade-boot.md](docs/DEMO-1-upgrade-boot.md).

### Démo 2 — Bibliothèque partagée

```bash
./demo/reset-demo.sh
export SPRING_ADVISOR_MAPPING_CUSTOM_0_FILEPATH="$(pwd)/demo/mappings/acme-spring-commons.json"
cd spring-petclinic
advisor upgrade-plan get
```

Voir [docs/DEMO-2-custom-upgrades.md](docs/DEMO-2-custom-upgrades.md).

## Désinstallation

```bash
./uninstall.sh    # arrête les conteneurs, supprime le clone petclinic
./cleanup.sh      # supprime aussi images, .envrc, tarball CLI
```

Ces scripts **ne suppriment pas** tout le cache `~/.m2`.

## Ressources complémentaires

- [Introduction Application Advisor (Spring Academy)](https://spring.academy/guides/app-advisor-intro)
- [Upgrade Spring Boot 2.7 → 4.0](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/application-advisor/1-6/app-advisor/how-to-guides-upgrade-boot.html)
- [Custom upgrade mappings](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/application-advisor/1-6/app-advisor/custom-upgrades.html)
- [Spring Enterprise — développeurs](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/tanzu-spring/commercial/spring-tanzu/guide-artifact-repository-developers.html)
- [Spring Enterprise — administrateurs](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/tanzu-spring/commercial/spring-tanzu/guide-artifact-repository-administrators.html)

---

### Utilisateurs Windows

Cette démo est testée sur **macOS et Linux**. Sous Windows, utilisez **WSL2** (Ubuntu) et exécutez `./install.sh` dans WSL, ou installez manuellement :

- Téléchargez `application-advisor-cli-windows-1.6.3` depuis le dépôt Spring Enterprise
- Configurez `%USERPROFILE%\.m2\settings.xml` à partir de `config/settings-maven-direct.xml.template`
- Utilisez `mvnw.cmd` au lieu de `./mvnw`
