# Frontend dependency backup (offline)

Frozen copies of **`node_modules`** and **`bower_components`** so builds never depend on npm or Bower registries again.

## Layout

```
tcamt-lite-client/deps-backup/v1/
  node_modules/       # npm toolchain + grunt stack (~250 MB)
  bower_components/   # Angular, Froala, etc. (~180 MB)
  package-lock.json
  bower.json
  .nvmrc
  manifest.json       # date, Node version, sizes
```

## Create backup (once, while registries still work)

From repo root:

```bash
./scripts/backup-frontend-deps.sh create v1
```

This runs `npm ci` + `bower install` if needed, then **copies** everything into `deps-backup/v1/`.

## Restore (no npm / bower)

```bash
./scripts/backup-frontend-deps.sh restore v1
cd tcamt-lite-client
npx grunt build --prod
```

## Keep it safe

The backup folders are **gitignored** (~430 MB total). Copy `deps-backup/v1/` to:

- Team NAS / shared drive
- S3 or similar
- A GitHub Release asset (zip the folder)
- Optional: remove gitignore lines and commit (not recommended for git performance)

**Do not delete** after creating — this is your insurance against retired packages.

## Refresh (rare)

Only when intentionally upgrading frontend dependencies:

```bash
# update package.json / bower.json on a branch
./scripts/backup-frontend-deps.sh create v2
```

See **`FRONTEND-SNAPSHOT.md`** for CI and backend-only build notes.
