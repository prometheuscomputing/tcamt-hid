#!/usr/bin/env bash
# Fail if Froala key or other secrets look baked into the WAR or properties before publish.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAR="${ROOT_DIR}/tcamt-lite-controller/target/tcamt.war"
PROPS="${ROOT_DIR}/tcamt-lite-controller/src/main/resources/app-web-config.properties"

fail() {
  echo "verify-no-secrets: $*" >&2
  exit 1
}

# Source properties (must stay empty in git; do not commit real keys)
if grep -E '^froala\.key=[^[:space:]]+' "$PROPS" >/dev/null 2>&1; then
  fail "froala.key is set in app-web-config.properties — use runtime FROALA_KEY / -Dfroala.key only"
fi

if [ ! -f "$WAR" ]; then
  fail "missing $WAR — run mvn clean install -DskipTests first"
fi

# WAR classpath copy must not contain a non-empty froala.key
war_props="$(unzip -p "$WAR" WEB-INF/classes/app-web-config.properties 2>/dev/null || true)"
if printf '%s' "$war_props" | grep -E '^froala\.key=[^[:space:]]+' >/dev/null 2>&1; then
  fail "froala.key is non-empty inside tcamt.war — rebuild without embedding secrets"
fi

# Obvious Froala key pattern (32+ char alphanumeric segments from license keys)
if unzip -p "$WAR" WEB-INF/classes/app-web-config.properties 2>/dev/null | grep -E 'froala\.key=.*[A-Za-z0-9]{20,}' >/dev/null; then
  fail "possible Froala license material found in WAR properties"
fi

echo "verify-no-secrets: OK (froala.key not embedded in WAR)"
