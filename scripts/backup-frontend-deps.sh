#!/usr/bin/env bash
# Copy node_modules + bower_components into deps-backup/ for offline restores.
#
# Usage:
#   ./scripts/backup-frontend-deps.sh create [label]   # default v1
#   ./scripts/backup-frontend-deps.sh restore [label]
#   ./scripts/backup-frontend-deps.sh status [label]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT_DIR="${ROOT_DIR}/tcamt-lite-client"
BACKUP_ROOT="${CLIENT_DIR}/deps-backup"
LABEL="${2:-v1}"
BACKUP_DIR="${BACKUP_ROOT}/${LABEL}"

usage() {
  cat <<EOF
Usage: $0 create|restore|status [label]

  create   npm ci + bower install (if needed), then copy into deps-backup/<label>/
  restore  Copy deps-backup/<label>/ back into tcamt-lite-client/ (no npm/bower)
  status   Show whether backup exists and sizes

Default label: v1
Backup layout:
  tcamt-lite-client/deps-backup/v1/node_modules/
  tcamt-lite-client/deps-backup/v1/bower_components/
  tcamt-lite-client/deps-backup/v1/package-lock.json
  tcamt-lite-client/deps-backup/v1/bower.json
  tcamt-lite-client/deps-backup/v1/.nvmrc
  tcamt-lite-client/deps-backup/v1/manifest.json
EOF
}

dir_size() {
  du -sh "$1" 2>/dev/null | awk '{print $1}'
}

ensure_deps_installed() {
  cd "$CLIENT_DIR"
  if [ ! -d node_modules ] || [ ! -d bower_components ]; then
    echo "Installing dependencies before backup..."
    git config --global url."https://github.com/".insteadOf "git://github.com/" 2>/dev/null || true
    git config --global url."https://github.com/".insteadOf "ssh://git@github.com/" 2>/dev/null || true
    npm ci --ignore-scripts
    npx bower install --allow-root
  fi
}

create_backup() {
  ensure_deps_installed
  mkdir -p "$BACKUP_DIR"

  echo "Backing up to ${BACKUP_DIR} (this may take a few minutes)..."
  rm -rf "${BACKUP_DIR}/node_modules" "${BACKUP_DIR}/bower_components"

  cp -R "${CLIENT_DIR}/node_modules" "${BACKUP_DIR}/"
  cp -R "${CLIENT_DIR}/bower_components" "${BACKUP_DIR}/"
  cp "${CLIENT_DIR}/package-lock.json" "${BACKUP_DIR}/"
  cp "${CLIENT_DIR}/bower.json" "${BACKUP_DIR}/"
  cp "${CLIENT_DIR}/.nvmrc" "${BACKUP_DIR}/"

  cat > "${BACKUP_DIR}/manifest.json" <<EOF
{
  "label": "${LABEL}",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "node": "$(node -v 2>/dev/null || echo unknown)",
  "npm": "$(npm -v 2>/dev/null || echo unknown)",
  "node_modules_size": "$(dir_size "${BACKUP_DIR}/node_modules")",
  "bower_components_size": "$(dir_size "${BACKUP_DIR}/bower_components")",
  "notes": "Restore with: ./scripts/backup-frontend-deps.sh restore ${LABEL}"
}
EOF

  echo "Backup complete: ${BACKUP_DIR}"
  echo "  node_modules:      $(dir_size "${BACKUP_DIR}/node_modules")"
  echo "  bower_components:  $(dir_size "${BACKUP_DIR}/bower_components")"
  echo ""
  echo "Keep this folder safe (copy to team storage). It avoids npm install / bower install forever."
}

restore_backup() {
  if [ ! -d "${BACKUP_DIR}/node_modules" ] || [ ! -d "${BACKUP_DIR}/bower_components" ]; then
    echo "Missing backup at ${BACKUP_DIR}" >&2
    echo "Run: $0 create ${LABEL}" >&2
    exit 1
  fi

  cd "$CLIENT_DIR"
  echo "Restoring from ${BACKUP_DIR}..."
  rm -rf node_modules bower_components
  cp -R "${BACKUP_DIR}/node_modules" .
  cp -R "${BACKUP_DIR}/bower_components" .
  cp "${BACKUP_DIR}/package-lock.json" .
  cp "${BACKUP_DIR}/bower.json" .
  cp "${BACKUP_DIR}/.nvmrc" .

  echo "Restored. You can run: cd tcamt-lite-client && npx grunt build --prod"
  echo "No npm install or bower install required."
}

status_backup() {
  if [ ! -f "${BACKUP_DIR}/manifest.json" ]; then
    echo "No backup found at ${BACKUP_DIR}"
    exit 1
  fi
  echo "Backup: ${BACKUP_DIR}"
  cat "${BACKUP_DIR}/manifest.json"
}

cmd="${1:-}"
case "$cmd" in
  create) create_backup ;;
  restore) restore_backup ;;
  status) status_backup ;;
  *) usage; exit 2 ;;
esac
