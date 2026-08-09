#!/usr/bin/env bash
# Exit 0 if a Grunt production build is required, 1 if Maven can use committed webapp.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT_DIR="${ROOT_DIR}/tcamt-lite-client"
WEBAPP_INDEX="${ROOT_DIR}/tcamt-lite-controller/src/main/webapp/index.html"

FRONTEND_PATHS=(
  "tcamt-lite-client/app"
  "tcamt-lite-client/bower.json"
  "tcamt-lite-client/package.json"
  "tcamt-lite-client/package-lock.json"
  "tcamt-lite-client/Gruntfile.js"
  "tcamt-lite-client/.nvmrc"
)

if [ ! -f "$WEBAPP_INDEX" ]; then
  echo "needs-frontend-build: yes (missing ${WEBAPP_INDEX})" >&2
  exit 0
fi

# Prefer git: frontend changed since the previous release tag?
PREV_TAG="$(git -C "$ROOT_DIR" describe --tags --abbrev=0 HEAD^ 2>/dev/null || true)"
if [ -n "$PREV_TAG" ]; then
  if git -C "$ROOT_DIR" diff --name-only "$PREV_TAG" HEAD -- "${FRONTEND_PATHS[@]}" | grep -q .; then
    echo "needs-frontend-build: yes (frontend paths changed since ${PREV_TAG})" >&2
    exit 0
  fi
  echo "needs-frontend-build: no (webapp committed; no frontend changes since ${PREV_TAG})" >&2
  exit 1
fi

# Fallback: compare newest frontend source mtime to built index.html
file_mtime() {
  if stat --version 2>/dev/null | grep -q GNU; then
    stat -c '%Y' "$1"
  else
    stat -f '%m' "$1"
  fi
}

WEBAPP_MTIME="$(file_mtime "$WEBAPP_INDEX")"
NEWEST_SRC_MTIME="$WEBAPP_MTIME"
while IFS= read -r -d '' path; do
  mtime="$(file_mtime "$path")"
  if [ "$mtime" -gt "$NEWEST_SRC_MTIME" ]; then
    NEWEST_SRC_MTIME="$mtime"
  fi
done < <(
  find "${CLIENT_DIR}/app" \
    "${CLIENT_DIR}/bower.json" \
    "${CLIENT_DIR}/package.json" \
    "${CLIENT_DIR}/package-lock.json" \
    "${CLIENT_DIR}/Gruntfile.js" \
    -type f -print0 2>/dev/null
)

if [ "$NEWEST_SRC_MTIME" -gt "$WEBAPP_MTIME" ]; then
  echo "needs-frontend-build: yes (frontend sources newer than webapp/index.html)" >&2
  exit 0
fi

echo "needs-frontend-build: no (committed webapp is up to date)" >&2
exit 1
