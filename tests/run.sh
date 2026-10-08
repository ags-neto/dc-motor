#!/usr/bin/env bash
# tests/run.sh — checks for the dc-motor documentation repository.
#
#   bash tests/run.sh              check the checkout this script lives in
#   bash tests/run.sh <dir>        check another checkout
#   bash tests/run.sh --self-test  negative proofs: every check must fail when broken
#
# There is no code in this repository, so this is not a code test suite. It checks the
# documentation itself (the README is present and every internal reference in it resolves)
# and the hygiene of the tree (no editor junk, no file with the shape of a secret).
set -u

checks() {
  python3 - "$1" <<'PY'
import os, re, sys

root = sys.argv[1]
failures = []


def ok(msg):
    print("  ok    %s" % msg)


def bad(msg):
    print("  FAIL  %s" % msg)
    failures.append(msg)


# ---- the tree, ignoring .git ---------------------------------------------------------------
tree = []
for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = [d for d in dirnames if d != ".git"]
    for name in filenames:
        tree.append(os.path.relpath(os.path.join(dirpath, name), root))
tree.sort()

# ---- 1. the README exists and is not empty -------------------------------------------------
readme = os.path.join(root, "README.md")
text = ""
if os.path.isfile(readme) and os.path.getsize(readme) > 0:
    ok("README.md exists (%d bytes)" % os.path.getsize(readme))
    with open(readme, encoding="utf-8") as fh:
        text = fh.read()
else:
    bad("README.md is missing or empty")

# ---- 2. every internal reference resolves --------------------------------------------------
if text:
    refs = set()
    for target in re.findall(r"\]\(([^)\s]+)\)", text):
        refs.add(target)                                   # markdown links and images
    body = re.sub(r"```.*?```", "", text, flags=re.S)      # ignore fenced blocks
    for span in re.findall(r"`([^`\n]+)`", body):
        if re.match(r"^[A-Za-z0-9_][A-Za-z0-9_./-]*"
                    r"\.(md|sh|py|ino|png|jpg|jpeg|svg|pdf|txt|json|ya?ml|gitignore)$", span):
            refs.add(span)                                 # inline-code file paths
    resolved, missing = 0, []
    for target in sorted(refs):
        if target.startswith("#") or re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", target):
            continue                                       # anchor or absolute/external URL
        path = target.split("#", 1)[0]
        if not path:
            continue
        if os.path.isfile(os.path.join(root, path)):
            resolved += 1
        else:
            missing.append(target)
    if missing:
        bad("internal reference(s) without a file: %s" % ", ".join(missing))
    else:
        ok("internal references resolve (%d file(s) cited)" % resolved)

# ---- 3. no editor junk ---------------------------------------------------------------------
junk = [p for p in tree
        if os.path.basename(p) in (".DS_Store", "Thumbs.db", ".AppleDouble")
        or p.endswith((".swp", ".swo", "~"))]
if junk:
    bad("editor junk present: %s" % ", ".join(junk))
else:
    ok("no editor junk (.DS_Store, Thumbs.db, *.swp, *~)")

# ---- 4. nothing with the name or the content shape of a secret ------------------------------
NAME = re.compile(r"(^|/)(\.env(\..*)?|id_rsa|id_ed25519"
                  r"|.*\.pem|.*\.key|secrets?\.[^/]*|.*credentials.*)$")
CONTENT = re.compile(
    r"-----BEGIN [A-Z ]*PRIVATE KEY-----"
    r"|AKIA[0-9A-Z]{16}"
    r"|gh[pousr]_[A-Za-z0-9]{20,}"
    r"|xox[baprs]-[A-Za-z0-9-]{10,}"
    r"|(password|passwd|secret|token|api[_-]?key)\s*[:=]\s*"
    r"[\"']?[A-Za-z0-9/+_-]{8,}",
    re.IGNORECASE,
)
by_name = [p for p in tree if NAME.search(p)]
by_content = []
for p in tree:
    try:
        with open(os.path.join(root, p), "rb") as fh:
            blob = fh.read()
    except OSError:
        continue
    if b"\0" in blob[:4096]:
        continue
    if CONTENT.search(blob.decode("utf-8", "replace")):
        by_content.append(p)
if by_name or by_content:
    if by_name:
        bad("secret-shaped file name(s): %s" % ", ".join(by_name))
    if by_content:
        bad("secret-shaped content in: %s" % ", ".join(by_content))
else:
    ok("no secret-shaped file name or content")

# ---- summary -------------------------------------------------------------------------------
if failures:
    print("  %d check(s) failed" % len(failures))
    sys.exit(1)
print("  all checks passed")
sys.exit(0)
PY
}

# ---- self-test: each check must fail when it is broken -------------------------------------
self_test() {
  tmp="$(mktemp -d)"
  rc=0
  negatives=0

  fixture() {  # fixture <name> -> a clean tree, echoing its path
    d="$tmp/$1"
    mkdir -p "$d"
    printf '# fixture\n\nSee [LICENSE](LICENSE).\n' > "$d/README.md"
    printf 'MIT\n' > "$d/LICENSE"
    printf '%s\n' "$d"
  }

  run() {  # run <expected-rc> <label> <dir>
    out="$(checks "$3" 2>&1)"
    got=$?
    if [ "$got" -eq "$1" ]; then
      printf '  ok    %s (rc=%s)\n' "$2" "$got"
      if [ "$1" -ne 0 ]; then
        negatives=$((negatives + 1))
      fi
    else
      printf '  FAIL  %s (rc=%s, expected %s)\n' "$2" "$got" "$1"
      rc=1
    fi
    printf '%s\n' "$out" | sed 's/^/          /'
  }

  echo "self-test — every check must fail when the thing it guards is broken:"
  d="$(fixture clean)"; run 0 "clean tree passes" "$d"

  d="$(fixture no-readme)"; rm "$d/README.md"
  run 1 "README removed -> fails" "$d"

  d="$(fixture no-license)"; rm "$d/LICENSE"
  run 1 "cited LICENSE missing -> fails" "$d"

  d="$(fixture no-image)"; printf '# fixture\n\n![screenshot](shot.png)\n' > "$d/README.md"
  run 1 "cited image missing -> fails" "$d"

  d="$(fixture junk)"; touch "$d/.DS_Store"
  run 1 "editor junk added -> fails" "$d"

  d="$(fixture secret)"
  # built at run time so that this script does not itself contain a secret-shaped literal
  printf '%s = "%s"\n' "pass""word" "hunter2""hunter2" > "$d/.env"
  run 1 "secret-shaped file added -> fails" "$d"

  if [ "$rc" -eq 0 ]; then
    echo "self-test passed: $negatives negative case(s) failed as expected"
  else
    echo "self-test FAILED"
  fi
  rm -rf "$tmp"
  return "$rc"
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
  exit $?
fi

root="$(cd "${1:-"$(dirname "${BASH_SOURCE[0]}")/.."}" && pwd)"
echo "checks for $root:"
checks "$root"
exit $?
