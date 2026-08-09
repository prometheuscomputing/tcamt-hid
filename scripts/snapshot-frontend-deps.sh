#!/usr/bin/env bash
# Create or restore an offline snapshot of node_modules + bower_components.
#
# Usage:
#   ./scripts/snapshot-frontend-deps.sh create [label]   # e.g. label v1
#   ./scripts/snapshot-frontend-deps.sh restore [label]
#   ./scripts/snapshot-frontend-deps.sh verify [label]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT_DIR="${ROOT_DIR}/tcamt-lite-client"
SNAPSHOT_DIR="${CLIENT_DIR}/snapshots"
LABEL="${2:-v1}"
ARCHIVE="${SNAPSHOT_DIR}/frontend-deps-${LABEL}.tar.gz"
MANIFEST="${SNAPSHOT_DIR}/frontend-deps-${LABEL}.manifest.json"

usage() {
  cat <<EOF
Usage: $0 create|restore|verify [label]

  create   Install deps (npm ci + bower), archive node_modules and bower_components.
  restore  Extract archived deps into tcamt-lite-client/ (offline rebuild).
  verify   Check archive checksum against manifest.

Default label: v1
Snapshots live in tcamt-lite-client/snapshots/ (archives are gitignored; manifest is committed).
EOF
}

create_snapshot() {
  mkdir -p "$SNAPSHOT_DIR"
  cd "$CLIENT_DIR"

  git config --global url."https://github.com/".insteadOf "git://github.com/" 2>/dev/null || true
  git config --global url."https://github.com/".insteadOf "ssh://git@github.com/" 2>/dev/null || true

  npm ci --ignore-scripts
  npx bower install --allow-root

  tar -czf "$ARCHIVE" node_modules bower_components package-lock.json bower.json .nvmrc
  sha256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
  size_bytes="$(wc -c < "$ARCHIVE" | tr -d ' ')"

  cat > "$MANIFEST" <<EOF
{
  "label": "${LABEL}",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "archive": "$(basename "$ARCHIVE")",
  "sha256": "${sha256}",
  "size_bytes": ${size_bytes},
  "node": "$(node -v)",
  "npm": "$(npm -v)",
  "notes": "Offline frontend toolchain snapshot. Do not regenerate unless intentionally upgrading deps."
}
EOF

  echo "Created ${ARCHIVE} ($(numfmt --to=iec "$size_bytes" 2>/dev/null || echo "${size_bytes} bytes"))"
  echo "Manifest: ${MANIFEST}"
  echo "Attach ${ARCHIVE} to a GitHub Release (e.g. frontend-deps-${LABEL}) or store in team artifact storage."
}

restore_snapshot() {
  if [ ! -f "$ARCHIVE" ]; then
    echo "Missing archive: ${ARCHIVE}" >&2
    echo "Download from the GitHub Release that published frontend-deps-${LABEL}." >&2
    exit 1
  fi
  verify_snapshot
  cd "$CLIENT_DIR"
  rm -rf node_modules bower_components
  tar -xzf "$ARCHIVE"
  echo "Restored deps from ${ARCHIVE}"
}

verify_snapshot() {
  if [ ! -f "$ARCHIVE" ] || [ ! -f "$MANIFEST" ]; then
    echo "Missing archive or manifest for label ${LABEL}" >&2
    exit 1
  fi
  expected="$(grep -o '"sha256": "[^"]*"' "$MANIFEST" | cut -d'"' -f4)"
  actual="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
  if [ "$expected" != "$actual" ]; then
    echo "Checksum mismatch for ${ARCHIVE}" >&2
    exit 1
  fi
  echo "OK: ${ARCHIVE}"
}

cmd="${1:-}"
case "$cmd" in
  create) create_snapshot ;;
  restore) restore_snapshot ;;
  verify) verify_snapshot ;;
  *) usage; exit 2 ;;
esac
