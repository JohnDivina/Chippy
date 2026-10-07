#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

# 1. Build the .app bundle first
"${SCRIPT_DIR}/package_app.sh"

DIST_DIR="dist"
STAGING_DIR="${DIST_DIR}/staging"
DMG_PATH="${DIST_DIR}/Chippy.dmg"

echo "💿 Preparing DMG staging directory..."
rm -rf "${DIST_DIR}"
mkdir -p "${STAGING_DIR}"

# Copy Chippy.app to staging
cp -R "build/Chippy.app" "${STAGING_DIR}/"

# Add Applications symlink for drag-and-drop installation
ln -s "/Applications" "${STAGING_DIR}/Applications"

echo "💿 Creating ${DMG_PATH} using native hdiutil..."
hdiutil create \
    -volname "Chippy" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

rm -rf "${STAGING_DIR}"

echo "🎉 DMG build complete: ${DMG_PATH}"
echo "You can now upload this DMG to GitHub Releases or double-click to install!"
