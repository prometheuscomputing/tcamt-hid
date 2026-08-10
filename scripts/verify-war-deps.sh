#!/usr/bin/env bash
# Fail if two jars in the WAR claim the SAME JAXP TransformerFactory class.
#
# Several XSLT engines can sit on the classpath happily, because each registers
# its own provider class through META-INF/services and only one is selected.
# This war legitimately carries both Xalan and Saxon-HE that way.
#
# What breaks is two jars declaring the same provider CLASS NAME. The service
# loader picks whichever it reaches first, and if that copy cannot be
# instantiated against the rest of the classpath then TransformerFactory
# creation throws, the Spring context fails to start, and Tomcat answers 404 on
# every path while still logging a successful startup.
#
# That happened with saxon 8.7 arriving transitively next to Saxon-HE 9.6: both
# name net.sf.saxon.TransformerFactoryImpl. The exclusion lives in
# tcamt-lite-controller/pom.xml; this check is here so a future dependency bump
# cannot reintroduce the same shape unnoticed.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAR="${ROOT_DIR}/tcamt-lite-controller/target/tcamt.war"
SERVICE="META-INF/services/javax.xml.transform.TransformerFactory"

fail() {
  echo "verify-war-deps: $*" >&2
  exit 1
}

[ -f "$WAR" ] || fail "missing $WAR — run mvn clean install -DskipTests first"

work="$(mktemp -d)"
[ -n "$work" ] && [ -d "$work" ] || fail "could not create a temporary directory"
cleanup() {
  if [ -n "${work:-}" ] && [ -d "${work:-}" ]; then
    rm -rf -- "$work"
  fi
}
trap cleanup EXIT

unzip -q -o "$WAR" 'WEB-INF/lib/*.jar' -d "$work" \
  || fail "could not read WEB-INF/lib from the war"

# Collect "<declared provider class> <jar>" for every jar that registers one.
declarations="$work/declarations.txt"
: > "$declarations"

while IFS= read -r jar; do
  # Capture each listing before testing it. Piping into `grep -q` would let grep
  # exit on the first match, send SIGPIPE to unzip, and with pipefail turn a
  # successful match into a non-zero pipeline status, so matches get missed.
  listing="$(unzip -Z1 "$jar" 2>/dev/null || true)"
  case $'\n'"$listing"$'\n' in
    *$'\n'"$SERVICE"$'\n'*) ;;
    *) continue ;;
  esac
  declared="$(unzip -p "$jar" "$SERVICE" 2>/dev/null || true)"
  while IFS= read -r line; do
    # Service files allow comments and blank lines.
    line="${line%%#*}"
    line="$(printf '%s' "$line" | tr -d '[:space:]')"
    [ -n "$line" ] || continue
    printf '%s %s\n' "$line" "$(basename "$jar")" >> "$declarations"
  done <<< "$declared"
done < <(find "$work/WEB-INF/lib" -name '*.jar' | sort)

if [ ! -s "$declarations" ]; then
  echo "verify-war-deps: OK (no bundled XSLT provider; the JDK default is used)"
  exit 0
fi

conflict=0
while IFS= read -r cls; do
  jars="$(awk -v c="$cls" '$1 == c { printf "%s ", $2 }' "$declarations")"
  n="$(awk -v c="$cls" '$1 == c { n++ } END { print n+0 }' "$declarations")"
  if [ "$n" -gt 1 ]; then
    echo "verify-war-deps: ${cls} is declared by ${n} jars: ${jars}" >&2
    conflict=1
  fi
done < <(awk '{ print $1 }' "$declarations" | sort -u)

[ "$conflict" -eq 0 ] \
  || fail "two jars claim the same TransformerFactory class — exclude the unwanted one in the pom"

echo "verify-war-deps: OK ($(awk '{ print $1 }' "$declarations" | sort -u | wc -l | tr -d ' ') distinct XSLT provider(s), none duplicated)"
