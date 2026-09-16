# TCAMT Docker images

How published container images are versioned, when they are built, and how to pull them from GitHub Container Registry (GHCR).

---

## Image location

```
ghcr.io/prometheuscomputing/tcamt-hid
```

Full pull example:

```bash
docker pull ghcr.io/prometheuscomputing/tcamt-hid:2.1.0
```

- **Platform:** `linux/amd64`
- **App URL path:** `/tcamt/` (e.g. `http://host:8080/tcamt/`)

> **Note:** Official Prometheus releases are published to GHCR (below). For other registries (ECR, Docker Hub, private Nexus), set **`IMAGE_NAME`** when building — see **`BUILD.md`**.

---

## Versioning

The Docker tag **is the GitHub Release tag**. There is no separate version file used for images (e.g. `pom.xml` is not the source of truth for Docker tags).

| Docker tag | How it is set |
|------------|----------------|
| `2.1.0` | Release tag with optional `v` prefix removed (`v2.1.0` → also tagged `2.1.0`) |
| `v2.1.0` | Exact Git tag name, when the release tag includes `v` |
| `latest` | Always points to the **most recently published** release |

**Convention:** use semver release tags such as `2.1.0` or `v2.1.0`.

### When an image is built

| Event | Publishes image? |
|-------|------------------|
| **GitHub Release published** | Yes |
| Release saved as draft only | No |
| PR merged (no release) | No |
| Push to a branch (no release) | No |

Workflow: **Actions → Publish TCAMT image** (runs on `release: published`).

### How to publish a new version (maintainers)

1. Merge changes into **`transition`** via pull request.
2. Create a Git tag on the commit to ship (e.g. `v2.1.0`).
3. Open **GitHub → Releases → Draft a new release**, select that tag, and click **Publish release**.
4. GitHub Actions builds the WAR, verifies no secrets are embedded, builds the Docker image, and pushes these tags:
   - `ghcr.io/prometheuscomputing/tcamt-hid:<release-tag>`
   - `ghcr.io/prometheuscomputing/tcamt-hid:<version>` (without leading `v`)
   - `ghcr.io/prometheuscomputing/tcamt-hid:latest`

---

## Pulling an image

### Who can pull

Members of the [**healthit** team](https://github.com/orgs/prometheuscomputing/teams/healthit) with access to this repository can pull **private** packages using their **own** GitHub account. The package does not need to be public, and you do not need a token from whoever published the image.

### One-time login to GHCR

Create a personal access token at **GitHub → Settings → Developer settings → Personal access tokens** with at least:

- **`read:packages`**
- **`repo`** (if the package is private)

Then log in:

```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

With GitHub CLI (after `gh auth refresh -h github.com -s read:packages`):

```bash
echo "$(gh auth token)" | docker login ghcr.io -u "$(gh api user -q .login)" --password-stdin
```

### Pull by version

Pin to a specific release (recommended for production):

```bash
docker pull ghcr.io/prometheuscomputing/tcamt-hid:2.1.0
```

Use the latest published release:

```bash
docker pull ghcr.io/prometheuscomputing/tcamt-hid:latest
```

If the release tag includes `v`, both tags exist:

```bash
docker pull ghcr.io/prometheuscomputing/tcamt-hid:v2.1.0
docker pull ghcr.io/prometheuscomputing/tcamt-hid:2.1.0
```

### Run (minimal example)

```bash
docker run --rm -p 8080:8080 \
  -e FROALA_KEY="your-key" \
  -e DB_HOST=... -e DB_NAME=tcamt_db -e DB_USER=tcamt -e DB_PASSWORD=... \
  -e MONGO_HOST=... \
  ghcr.io/prometheuscomputing/tcamt-hid:2.1.0
```

For local development with MySQL/Mongo, see **`healthit-local-setup`** Compose files.

---

## Runtime configuration (not in the image)

Everything a deployment differs in is read by `docker/entrypoint.sh` from the
environment when the container starts. The image carries neutral defaults
(`mail.host=localhost`, no-reply addresses, an empty Froala key), so a
container started without these variables serves the application but talks
to no real mail relay.

| Variable | Purpose |
|----------|---------|
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | MySQL account database, written into the `jdbc/igl_jndi` datasource. Required: the container refuses to start without the host, user and password, because without the datasource every login fails while the pages still answer. |
| `MONGO_HOST`, `MONGO_PORT`, `MONGO_DBNAME` (`MONGO_USER`, `MONGO_PASSWORD`, `MONGO_AUTHSOURCE` when the server authenticates) | Test plan store (use **Mongo 4.4**) |
| `MAIL_HOST`, `MAIL_PORT`, `MAIL_PROTOCOL`, `MAIL_AUTH`, `MAIL_STARTTLS_ENABLE`, `MAIL_DEBUG`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM` | Account emails (registration, approval, password reset). `MAIL_FROM` is also the sender address the pages show. |
| `ADMIN_EMAIL` | Where new registrations are announced, and the help address quoted in the emails |
| `FROALA_KEY` | Froala v2 editor licence |
| `APP_VERSION` | Version label shown in the header and on `api/appInfo` (CI sets it to the release tag in the smoke test) |
| `CONNECT_SERVER_URL_FROM`, `CONNECT_SERVER_URL_TO` | Optional. The GVT address the browser is given is `connect.apps` in the properties (the public one). When the server has to reach GVT through another address, for example a private network name behind a proxy that answers the public host with an HTML challenge, set both and the server swaps that prefix before calling GVT. Only the server side is affected; the browser keeps the public address for the post-push redirect. |
| `HBM2DDL_AUTO`, `HIBERNATE_DIALECT` | Schema handling; default `update` so an empty database gets its schema on first boot |

Each of these becomes a `-D` system property, which the application reads
ahead of `app-web-config.properties`.

---

## Troubleshooting

| Problem | What to do |
|---------|------------|
| `403 Forbidden` / `unauthorized` on pull | Log in to `ghcr.io`; ensure your token has **`read:packages`** |
| `denied` after login | Ask an org admin to grant [**healthit**](https://github.com/orgs/prometheuscomputing/teams/healthit) read access: **Packages → tcamt-hid → Package settings → Manage access** |
| Tag not found | Confirm a **published** GitHub Release exists for that version |
| App up but empty data | Image is fine — configure MySQL/Mongo and restore data separately |

---

## Related docs

- **`BUILD.md`** — build the WAR and Docker image from source locally
