#!/usr/bin/env bash
# Fixes the Flutter snap missing native build tools (ld, ar, strip, objcopy)
# by bind-mounting a patched copy of the LLVM bin directory.
#
# Requires sudo. Safe to run multiple times (idempotent).

set -euo pipefail

SNAP_BIN="/snap/flutter/current/usr/lib/llvm-10/bin"
FIX_DIR="/tmp/flutter-snap-toolchain"

# Skip if ld is already available (bind mount already active or snap fixed)
if [ -x "${SNAP_BIN}/ld" ] 2>/dev/null; then
  exit 0
fi

echo "🔧 Patching Flutter snap toolchain..."

rm -rf "${FIX_DIR}"
mkdir -p "${FIX_DIR}"

# Copy original snap binaries
cp "${SNAP_BIN}"/* "${FIX_DIR}/"

# Add missing system tools
for tool in ld ar strip objcopy; do
  if command -v "${tool}" &>/dev/null; then
    cp "$(command -v "${tool}")" "${FIX_DIR}/"
  fi
done

# Bind mount the patched directory over the snap one
sudo mount --bind "${FIX_DIR}" "${SNAP_BIN}"

echo "✅ Flutter snap toolchain patched (ld, ar, strip, objcopy added)"
