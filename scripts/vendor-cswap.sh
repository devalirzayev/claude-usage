#!/bin/bash
# Builds a self-contained cswap bundle with PyInstaller and stores it at
# Vendor/cswap.zip. The zip is committed so the app builds without any
# Python tooling; rerun this script to update the vendored version.
#
# Requires a Python >= 3.12 with a shared libpython (python.org or Homebrew
# builds work; uv-managed interpreters may not).

set -euo pipefail

CSWAP_VERSION="${CSWAP_VERSION:-0.18.1}"
PYTHON="${PYTHON:-python3}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/cswap-vendor.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

"$PYTHON" -m venv "$WORK/venv"
"$WORK/venv/bin/pip" install --quiet --upgrade pip
"$WORK/venv/bin/pip" install --quiet "claude-swap==$CSWAP_VERSION" pyinstaller

cat > "$WORK/entry.py" <<'EOF'
import sys

from claude_swap.cli import main

if __name__ == "__main__":
    sys.exit(main())
EOF

"$WORK/venv/bin/pyinstaller" \
    --noconfirm \
    --onedir \
    --name cswap \
    --collect-all claude_swap \
    --collect-all textual \
    --copy-metadata claude-swap \
    --collect-submodules keyring.backends \
    --copy-metadata keyring \
    --distpath "$WORK/dist" \
    --workpath "$WORK/build" \
    --specpath "$WORK" \
    "$WORK/entry.py"

"$WORK/dist/cswap/cswap" --version

mkdir -p "$ROOT/Vendor"
rm -f "$ROOT/Vendor/cswap.zip"
ditto -c -k --keepParent "$WORK/dist/cswap" "$ROOT/Vendor/cswap.zip"

echo "Vendored cswap $CSWAP_VERSION -> Vendor/cswap.zip"
