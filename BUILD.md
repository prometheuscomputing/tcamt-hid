# Building TCAMT

How to build the **WAR** (frontend + Java backend) and optionally the **Docker** image.

---

## Quick start (full WAR)

From the repository root:

```bash
cd tcamt-lite-client
nvm use                    # optional; uses Node 13.12.0 from .nvmrc
npm install                # first time, or when package-lock.json changes
npx bower install          # first time only, if bower_components/ is missing
npx grunt build --prod   # production assets → tcamt-lite-controller/src/main/webapp/
cd ..
mvn clean install -DskipTests
```

**Output:** `tcamt-lite-controller/target/tcamt.war`

Deploy to Tomcat at context path **`/tcamt`** (e.g. `http://localhost:8080/tcamt/`).

---

## Prerequisites

### Backend

| Tool | Version | Notes |
|------|---------|-------|
| **JDK** | **8+** (target **1.8**) | JDK 11+ works; POM compiles as Java 8 |
| **Maven** | **3.6+** | |
| **Network** | NIST Nexus reachable | `gov.nist:hl7-v2-validation`, `validation-proxy`, etc. |

NIST Maven repositories (parent `pom.xml`):

- `https://hit-nexus.nist.gov/repository/releases/`
- `https://hit-nexus.nist.gov/repository/public/`
- `https://hit-nexus.nist.gov/repository/snapshots/`

### Frontend (`tcamt-lite-client/`)

| Tool | Version | Notes |
|------|---------|-------|
| **Node.js** | **13.12.0** | Pinned in `tcamt-lite-client/.nvmrc` |
| **npm** | **6.14.4** | Bundled with Node 13 |
| **Bower** | via npm | `./node_modules/.bin/bower` |

Key frontend stack (from `bower.json`):

- Angular **1.5.5**, Angular Material **1.1.0**, Froala **~2.3.4**
- Grunt **0.4.5** + **grunt-cli** **1.4.3**
- Dart Sass **1.49.11** (via `sass` npm package)

---

## First-time setup (frontend)

```bash
cd tcamt-lite-client
nvm install 13.12.0 && nvm use    # if nvm is available
npm install                       # installs from package-lock.json
npx bower install                 # populates bower_components/
```

### Preserve existing `node_modules` and `bower_components`

Both folders are **gitignored**. On a machine that already has them:

- **Do not delete** working copies.
- **Do not run** `npm update` or `bower update` — use `npm install` / `bower install` only.
- **`package-lock.json`** and **`bower.json`** pin versions; commit lockfile changes intentionally.

If installs fail on `git://` URLs:

```bash
git config --global url."https://github.com/".insteadOf "git://github.com/"
```

---

## Build steps explained

### 1. Frontend — `npx grunt build --prod`

Runs the Grunt **`build`** task with the **`--prod`** flag, which:

- Uses **`app/prod/`** sources (`includeSource:prod`, `wiredep:prod`)
- Compiles SCSS with **Dart Sass** (not Ruby Compass)
- Minifies and copies assets into **`tcamt-lite-controller/src/main/webapp/`**

After `npm install`, you can also run `./node_modules/.bin/grunt build --prod`.

Dev server (no WAR rebuild):

```bash
cd tcamt-lite-client
npm install
npx bower install    # if needed
npx grunt serve      # http://localhost:9000
```

### 2. Backend — `mvn clean install`

Builds all modules in the reactor:

| Module | Artifact |
|--------|----------|
| `hit-resource-client/` | `hit-resource-client-2.0.3.jar` (vendored) |
| `tcamt-acmgt/` | account management (vendored) |
| `tcamt-lite-domain` … `tcamt-lite-service` | internal JARs |
| `tcamt-lite-controller` | **`tcamt.war`** |

No separate **hit-resource-client** checkout or **igamt-lite-acmgt** repo is required.

Skip tests:

```bash
mvn clean install -DskipTests
```

Maven-only rebuild (UI unchanged):

```bash
mvn clean install -DskipTests
```

---

## Froala editor (rich text)

TCAMT uses **Froala v2** (`angular-froala` ~2.3.4 in `bower.json`) for test-story and document editing. The license key is **not** hardcoded in the frontend — it is loaded at runtime from the server.

### How it works

1. Backend exposes the key on **`/api/appInfo`** as **`froalaKey`** (`AppInfo.java`).
2. Frontend **`FroalaOptionsService.js`** builds editor options from that response.
3. Controllers bind `froala="froalaEditorOptions"` on textareas (test plans, test cases, docs, etc.).

### Setting the key

| Deployment | How to set |
|------------|------------|
| **Properties file** | `froala.key=` in `tcamt-lite-controller/src/main/resources/app-web-config.properties` |
| **JVM system property** | `-Dfroala.key=YOUR_KEY` on Tomcat / `JAVA_OPTS` |
| **Docker (local Compose)** | `FROALA_KEY=...` in `tcamt/.env` under **`healthit-local-setup`** — passed through by `entrypoint.sh` as `-Dfroala.key=...` |

Example (`healthit-local-setup/tcamt/.env`):

```bash
FROALA_KEY=your-froala-v2-license-key
```

Then restart the app container:

```bash
docker compose restart tcamt
```

Example for Tomcat / standalone WAR:

```bash
export JAVA_OPTS="$JAVA_OPTS -Dfroala.key=your-froala-v2-license-key"
```

**Do not commit real license keys** to git. Keep them in `.env`, server env, or deployment secrets only.

**Do not bake keys into Docker images.** The WAR ships with `froala.key=` empty. Production and local Docker inject the key at **runtime** only (`FROALA_KEY` / `-Dfroala.key`). Before `docker push`, run:

```bash
./scripts/verify-no-secrets.sh
```

`build.sh` runs this check automatically after Maven. Never put `FROALA_KEY` in the Dockerfile, build args, or `app-web-config.properties` in git.

### Without a key

The editor may still load but show Froala branding/watermark or hit license warnings. Image/file upload URLs come from `appInfo.uploadedImagesUrl` and work independently of the key.

### Dev server note

`grunt serve` (port 9000) proxies API calls to Tomcat when using the full Compose stack. The Froala key is only available once **`AppInfo.get()`** succeeds against a running backend with `froala.key` / `FROALA_KEY` configured.

---

## Docker image

### What `build.sh` does

1. **`mvn clean install -DskipTests`** in this repo
2. **`docker buildx build`** → `tcamt-prm/tcamt-webapp:<version>`

**Important:** run **`npx grunt build --prod`** in `tcamt-lite-client/` first if you changed frontend code — `build.sh` does not run Grunt.

```bash
cd tcamt-lite-client && npx grunt build --prod && cd ..
./build.sh -v 1.0.0-local -l
```

| Flag | Meaning |
|------|---------|
| **`-v`** | Docker image tag (required), e.g. `1.0.0-local` |
| **`-l`** | Also tag as `tcamt-prm/tcamt-webapp:latest` |
| **`-p`** | Push to registry (after `docker login`) |

Maven only (no Docker):

```bash
mvn clean install -DskipTests
```

### Single-platform Docker (if buildx load fails)

```bash
cd tcamt-lite-client && npx grunt build --prod && cd ..
mvn clean install -DskipTests
docker buildx build --platform linux/amd64 --load -t tcamt-prm/tcamt-webapp:1.0.0-local .
docker tag tcamt-prm/tcamt-webapp:1.0.0-local tcamt-prm/tcamt-webapp:latest
```

Base image (root `Dockerfile`): **Tomcat 9.0.105** on **JDK 8** (Temurin).

The Dockerfile copies only **`error.html`** and **`tcamt.war`**. `.dockerignore` excludes `.env`, secrets, and source trees. **Secrets are runtime config** (Compose `.env`, AWS env/Secrets Manager) — not image layers.

### Pulling a published image (HealthIT team)

Pre-built images are published to **GitHub Container Registry (GHCR)** from the **`transition`** branch via the **Publish TCAMT image** GitHub Actions workflow (Actions → workflow_dispatch).

**Image:** `ghcr.io/prometheuscomputing/tcamt-hid`

| Tag | Meaning |
|-----|---------|
| `2.1.0-transition.2` (example) | Specific release build |
| `transition` | Latest build from the `transition` branch |

**Access:** HealthIT / `prometheuscomputing` team members with access to this repo **do not** need the package to be public. Use your own GitHub account — you do not need a token from whoever published the image.

**One-time Docker login to GHCR:**

```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

Create the token at **GitHub → Settings → Developer settings → Personal access tokens** with at least **`read:packages`** (and **`repo`** if the package is private).

**Pull and run:**

```bash
docker pull ghcr.io/prometheuscomputing/tcamt-hid:2.1.0-transition.2
# or latest transition build:
docker pull ghcr.io/prometheuscomputing/tcamt-hid:transition
```

App context path: **`/tcamt/`** (e.g. `http://host:8080/tcamt/`).

**Runtime configuration (not in the image):**

| Setting | Notes |
|---------|--------|
| **`FROALA_KEY`** | Froala v2 license — set in env / `JAVA_OPTS` / Compose `.env` |
| **MySQL** | Application database |
| **MongoDB** | Test artifacts / grid storage |

If `docker pull` is denied, ask an org admin to confirm your team has **read** access under **Packages → tcamt-hid → Package settings → Manage access**.

### Publishing via GitHub Actions (maintainers)

On **`transition`**, run **Actions → Publish TCAMT image → Run workflow** and enter a tag (e.g. `2.1.0-transition.3`). The workflow builds frontend + Maven, runs `verify-no-secrets.sh`, and pushes to GHCR.

Manual publish (requires `write:packages` on your token):

```bash
cd tcamt-lite-client && npx grunt build --prod && cd ..
mvn clean install -DskipTests
./scripts/verify-no-secrets.sh
docker build --platform linux/amd64 -t ghcr.io/prometheuscomputing/tcamt-hid:YOUR_TAG .
docker push ghcr.io/prometheuscomputing/tcamt-hid:YOUR_TAG
```

---

## Vendored modules

### `hit-resource-client`

Java sources under `hit-resource-client/src/main/java` are vendored from the standalone HIT project (Maven coordinates `gov.nist.hit.resources.deploy:hit-resource-client:2.0.3`).

### `tcamt-acmgt`

Vendored from legacy **`igamt-lite-acmgt`**. The unused `igamt-lite-domain` dependency and test-only `SecurityRequestPostProcessors.java` were removed.

---

## Troubleshooting

### Maven

| Issue | Fix |
|-------|-----|
| Missing `gov.nist:*` artifacts | Check network access to `hit-nexus.nist.gov`; or install JARs into `~/.m2` from a machine that can reach Nexus |
| Stale “not found in Central” cache | Delete the folder under `~/.m2/repository/...` or run `mvn -U` once |

### Frontend

| Issue | Fix |
|-------|-----|
| Empty UI after clone | Run `npm install` and `npx bower install` in `tcamt-lite-client/` |
| Wrong Node version | `nvm use` in `tcamt-lite-client/` (expects **13.12.0**) |

---

## Removed / notes

- **`gov.cdc.phinvads:vocabServiceClient`** — removed from `tcamt-lite-service` (unused).
- HL7 profile XSD references point to **`prometheuscomputing/hl7-v2-schemas-hid`** (`main` branch).
