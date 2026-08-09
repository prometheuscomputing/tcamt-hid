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
  -e DB_HOST=... -e DB_PASSWORD=... \
  -e MONGO_HOST=... \
  ghcr.io/prometheuscomputing/tcamt-hid:2.1.0
```

For local development with MySQL/Mongo, see **`healthit-local-setup`** Compose files.

---

## Runtime configuration (not in the image)

These are **not** baked into the image. Set them at deploy time:

| Variable | Purpose |
|----------|---------|
| **`FROALA_KEY`** | Froala v2 editor license |
| **MySQL** | `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` |
| **MongoDB** | `MONGO_HOST`, `MONGO_PORT`, `MONGO_DBNAME` (use **Mongo 4.4**) |

The image is built with an empty `froala.key` in the WAR; runtime injection is required.

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
