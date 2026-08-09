# Building TCAMT (WAR + Docker image)

## What `build.sh` does

1. **`mvn clean install`** in **this repo** (`tcamt-2`) → builds the vendored **`hit-resource-client`** module (`gov.nist.hit.resources.deploy:hit-resource-client:2.0.3`), **`tcamt-acmgt`**, domain/repo/service/controller → **`tcamt-lite-controller/target/tcamt.war`**.
2. **`docker buildx build`** → image `tcamt-prm/tcamt-webapp:<version>` (and optionally `:latest`).

You **do not** need a separate **hit-resource-client** checkout or **old-igamt** / **igamt-lite-acmgt**.

## In-repo module `hit-resource-client`

Java sources under `hit-resource-client/src/main/java` are **vendored** from the standalone HIT **hit-resource-client** project (same Maven coordinates). They are compiled as **Java 8** via the parent **`tcamt-lite`** `maven-compiler-plugin` configuration so **JDK 11+** can build the whole reactor.

## In-repo module `tcamt-acmgt`

Java sources under `tcamt-acmgt/src/main/java/gov/nist/healthcare/nht/acmgt/` were **vendored** from the legacy **`igamt-lite-acmgt`** project (NIST public-domain headers preserved in each file). The original `igamt-lite-acmgt` POM depended on `igamt-lite-domain`, but **no** Java file in that module imported IGAMT types; that dependency was unused.

**Removed from the vendored tree:** `SecurityRequestPostProcessors.java` (Spring MVC test helpers only; required extra test-only deps and is not used at runtime).

## What you must provide

| Flag | Meaning |
|------|---------|
| **`-v`** | Docker image tag (e.g. `1.0.0-local`) |
| **`-l`** | (optional) Also tag **`tcamt-prm/tcamt-webapp:latest`** |
| **`-p`** | (optional) **Push** to Docker Hub (after `docker login`) |

## NIST Maven repository (parent `pom.xml`)

Dependencies such as **`gov.nist:hl7-v2-validation`** and **`validation-proxy`** are resolved from NIST’s public Nexus (HTTPS):

- `https://hit-nexus.nist.gov/repository/releases/`
- `https://hit-nexus.nist.gov/repository/snapshots/`

No manual JAR install is required if those endpoints are reachable from your network.

## Prerequisites

- **JDK 8** is what the POMs target; **JDK 11+** often works (this repo adds `javax.annotation-api` for `@PostConstruct` on newer JDKs).
- **Maven 3.6+**
- **Docker** (for images; **Buildx** optional—plain `docker build --load` from the repo root also works)

## Command template

```bash
./build.sh -v 1.0.0-local -l
```

Maven only (no Docker):

```bash
mvn clean install -DskipTests
```

## Multi-arch `buildx` and loading into Docker Desktop

`build.sh` uses `--platform linux/amd64,linux/arm64` **without** `--push`. If the Docker step fails to load locally, build one platform:

```bash
cd /path/to/tcamt-2
mvn clean install -DskipTests
docker buildx build --platform linux/amd64 --load -t tcamt-prm/tcamt-webapp:1.0.0-local .
docker tag tcamt-prm/tcamt-webapp:1.0.0-local tcamt-prm/tcamt-webapp:latest
```

## Frontend (Angular / Grunt)

The **WAR** does not replace the **Grunt** dev workflow. See `tcamt-lite-client/README.md` and `tcamt-deploy/readme.md`.

## CDC `vocabServiceClient` (removed)

`tcamt-lite-service` no longer declares **`gov.cdc.phinvads:vocabServiceClient`**; it was unused in Java sources.

## If Maven fails on missing artifacts

Typical issues:

- **Network** blocks **`hit-nexus.nist.gov`** (corporate firewall, offline builds). In that case install the missing `gov.nist:*` artifacts into `~/.m2` from an environment that can reach Nexus.
- Stale **“not found in Central”** cache: delete the artifact’s folder under `~/.m2/repository/...` or run **`mvn -U`** once.
