# Frontend build speed and dependency snapshots

How to skip unnecessary frontend rebuilds, and how to freeze `node_modules` / `bower_components` so retired npm/bower packages cannot break future builds.

See also **`BUILD.md`** (local build) and **`DOCKER.md`** (release images).

---

## Fast backend-only builds

The production UI is copied into **`tcamt-lite-controller/src/main/webapp/`** by Grunt. That folder is **committed to git** (hashed bundles like `scripts/plugins.de60cce4.js`).

So when you only change Java/backend code:

```bash
mvn clean install -DskipTests
```

No `npm install`, no Bower, no Grunt — Maven packages the **already committed** webapp into `tcamt.war`.

### When you must rebuild the frontend

Run Grunt only if you changed anything under:

- `tcamt-lite-client/app/`
- `tcamt-lite-client/bower.json`, `package.json`, `Gruntfile.js`, etc.

```bash
cd tcamt-lite-client
nvm use
npm ci --ignore-scripts    # or restore deps snapshot — see below
npx bower install --allow-root
npx grunt build --prod
cd ..
git add tcamt-lite-controller/src/main/webapp/
```

Then commit the updated webapp with your PR.

### CI / release images

The **Publish TCAMT image** workflow runs `scripts/needs-frontend-build.sh`:

| Situation | Frontend step |
|-----------|----------------|
| No frontend changes since previous release tag | **Skipped** — uses committed webapp |
| Frontend sources changed | **Runs** — npm, bower, grunt |

Backend-only releases are much faster.

---

## Immutable dependency snapshot

Lockfiles alone are not enough: npm packages can be **unpublished**, and Bower has **no lockfile** — only `bower.json` plus whatever lands in `bower_components/`.

Three layers of protection:

| Layer | What | Protects against |
|-------|------|------------------|
| 1 | **`package-lock.json`** (in git) | Accidental npm version drift |
| 2 | **`bower.json` pinned versions + git SHAs** | Accidental bower drift |
| 3 | **Offline deps snapshot** | Registry takedowns, retired packages |

### Create a snapshot (once, or when intentionally upgrading deps)

```bash
./scripts/snapshot-frontend-deps.sh create v1
```

This:

1. Runs `npm ci --ignore-scripts` and `bower install`
2. Archives `node_modules/`, `bower_components/`, lockfiles into  
   `tcamt-lite-client/snapshots/frontend-deps-v1.tar.gz`
3. Writes `frontend-deps-v1.manifest.json` (checksum, date, Node version)

**Store the `.tar.gz`** somewhere permanent:

- GitHub Release tagged e.g. **`frontend-deps-v1`** (recommended — attach the archive)
- Team artifact storage / S3
- Optional: Git LFS in-repo (large)

The **manifest** can be committed; the **archive** is gitignored (too large for normal git).

### Restore snapshot (offline rebuild)

```bash
# download frontend-deps-v1.tar.gz into tcamt-lite-client/snapshots/
./scripts/snapshot-frontend-deps.sh restore v1
cd tcamt-lite-client && npx grunt build --prod
```

No npm/bower registry access required.

### Optional: commit `bower_components/` to git

Many legacy Angular 1 projects commit **`bower_components/`** (~180 MB) so Bower is never needed again. To enable:

1. Remove `tcamt-lite-client/bower_components/` from `.gitignore`
2. Run `./scripts/snapshot-frontend-deps.sh create v1` once
3. Commit `bower_components/` + updated webapp

`node_modules/` (~250 MB) can stay in the tarball only unless you want full offline without any restore step.

---

## Recommended workflow

### Day to day (backend change)

```bash
mvn clean install -DskipTests
```

### Frontend change

```bash
./scripts/snapshot-frontend-deps.sh restore v1   # if archive present
# … or npm ci + bower install on first machine
cd tcamt-lite-client && npx grunt build --prod && cd ..
git add tcamt-lite-controller/src/main/webapp/
```

### New release (maintainer)

1. Merge PRs to `transition`
2. If frontend changed: ensure webapp is committed and up to date
3. Publish GitHub Release → Docker image builds (frontend step auto-skipped when possible)

### Refresh deps (rare, intentional)

1. Update `package.json` / `bower.json` on a branch
2. `./scripts/snapshot-frontend-deps.sh create v2`
3. Publish new **`frontend-deps-v2`** GitHub Release with the tarball
4. Rebuild webapp, commit, merge

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/needs-frontend-build.sh` | Exit 0 if Grunt is required; 1 if committed webapp is enough |
| `scripts/snapshot-frontend-deps.sh` | Create / restore / verify offline deps archive |

---

## Related

- **`BUILD.md`** — full WAR build from source
- **`DOCKER.md`** — release-based container images
