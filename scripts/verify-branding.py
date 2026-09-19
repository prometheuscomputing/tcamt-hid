#!/usr/bin/env python3
"""Fail the build when the WAR still carries NIST wording or NIST-era hooks.

Scans what a user can see or receive: the index page, the view templates,
the message bundle, the non-comment lines of app-web-config.properties and
the string constants of the account controller (the emails). Sentences listed
in scripts/brand-allowed.txt are removed first, matched as whole sentences
with loose whitespace so a re-wrapped paragraph still counts. Anything left
that says NIST or nist.gov fails, with the snippet, and so does the federal
analytics loader anywhere under the webapp.

    scripts/verify-branding.py [path/to/tcamt.war]
"""
import io
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WAR = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "tcamt-lite-controller/target/tcamt.war"
ALLOWED = ROOT / "scripts/brand-allowed.txt"

PATTERNS = ("NIST", "nist.gov")
HOOKS = ("dap.digitalgov.gov", "_fed_an_ua_tag")
CONTROLLER = "WEB-INF/classes/gov/nist/healthcare/tools/hl7/v2/tcamt/lite/web/controller/UserController.class"
TEXT_SURFACES = ("index.html", "lang/messages_en.properties")
ATTR = re.compile(r'(?:href|src|content|title|alt)\s*=\s*(?:"([^"]*)"|\'([^\']*)\'|([^\s>"\']+))', re.I)


def fail(msg):
    print("verify-branding: " + msg, file=sys.stderr)
    sys.exit(1)


def load_allowed():
    out = []
    for line in ALLOWED.read_text(encoding="utf-8").splitlines():
        phrase = line.strip()
        if not phrase or phrase.startswith("#"):
            continue
        words = phrase.split()
        file_name = len(words) == 1 and re.search(r"[_\-.]", phrase)
        if phrase.endswith((",", ";", "and", "or", "by", "that")) or (len(words) < 2 and not file_name):
            fail("allowed entry is a fragment, not a sentence or title: %r" % phrase)
        if not re.search(r"NIST|nist\.gov", phrase):
            fail("allowed entry never matches anything: %r" % phrase)
        out.append(phrase)
    return out


def scrub(text, allowed):
    for phrase in allowed:
        pattern = (r"(?<![A-Za-z0-9])" + r"\s+".join(re.escape(w) for w in phrase.split())
                   + r"(?![A-Za-z0-9])")
        text = re.sub(pattern, " ", text)
    return text


def visible(m):
    return " " + " ".join("".join(g) for g in ATTR.findall(m.group(0))) + " "


def hits_in(text, allowed):
    text = re.sub(r"<!--.*?-->", " ", text, flags=re.S)
    text = re.sub(r"<[^>]+>", visible, text)
    text = scrub(text, allowed)
    found = []
    for pattern in PATTERNS:
        for m in re.finditer(re.escape(pattern), text):
            lo, hi = max(0, m.start() - 50), min(len(text), m.end() + 50)
            found.append(re.sub(r"\s+", " ", text[lo:hi]).strip())
    return found


def class_strings(data):
    # Java class files keep string constants as modified UTF-8; the printable
    # runs are enough to catch a subject line or a signature.
    return "\n".join(s.decode("utf-8", "replace") for s in re.findall(rb"[\x20-\x7e]{6,}", data))


def main():
    if not WAR.is_file():
        fail("missing %s (run mvn clean install -DskipTests first)" % WAR)
    allowed = load_allowed()
    failures = 0
    with zipfile.ZipFile(WAR) as z:
        names = z.namelist()
        surfaces = [n for n in names if n in TEXT_SURFACES or (n.startswith("views/") and n.endswith(".html"))]
        if CONTROLLER not in names:
            fail("controller class not in the WAR: " + CONTROLLER)
        for name in surfaces:
            body = z.read(name).decode("utf-8", "replace")
            for hook in HOOKS:
                if hook in body:
                    print("%s: carries %s" % (name, hook))
                    failures += 1
            for snippet in hits_in(body, allowed):
                print("%s: %s" % (name, snippet))
                failures += 1
        props = z.read("WEB-INF/classes/app-web-config.properties").decode("utf-8", "replace")
        live = "\n".join(l for l in props.splitlines() if not l.lstrip().startswith("#"))
        for snippet in hits_in(live, allowed):
            print("app-web-config.properties: %s" % snippet)
            failures += 1
        for snippet in hits_in(class_strings(z.read(CONTROLLER)), allowed):
            print("UserController: %s" % snippet)
            failures += 1
        # a bundle that still swaps the public address in the browser, or a
        # script still talking to a NIST host, is a hook of the same kind
        for name in names:
            if name.startswith("scripts/") and name.endswith(".js"):
                body = z.read(name).decode("utf-8", "replace")
                for hook in HOOKS:
                    if hook in body:
                        print("%s: carries %s" % (name, hook))
                        failures += 1
    if failures:
        fail("%d finding(s); see above" % failures)
    print("verify-branding: OK (%d surfaces, %d approved sentences)" % (len(surfaces) + 2, len(allowed)))


if __name__ == "__main__":
    main()
