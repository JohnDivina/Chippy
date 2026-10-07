#!/usr/bin/env bash
set -euo pipefail

echo "🔨 Building Chippy in release mode..."
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

swift build -c release

APP_DIR="build/Chippy.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 Assembling ${APP_DIR} bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# Copy binary
cp ".build/release/Chippy" "${MACOS_DIR}/Chippy"
chmod +x "${MACOS_DIR}/Chippy"

# Copy resource bundles if generated (excluding test bundles)
for bundle in .build/release/*.bundle; do
    if [ -d "$bundle" ] && [[ "$bundle" != *Tests* ]]; then
        echo "📁 Copying resource bundle: $(basename "$bundle")"
        cp -R "$bundle" "${RESOURCES_DIR}/"
    fi
done

# Copy root resources
if [ -d "Resources" ]; then
    cp -R Resources/* "${RESOURCES_DIR}/" || true
fi

# Generate Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Chippy</string>
    <key>CFBundleIdentifier</key>
    <string>com.johndivina.chippy</string>
    <key>CFBundleName</key>
    <string>Chippy</string>
    <key>CFBundleDisplayName</key>
    <string>Chippy — AI Paradise</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "🔏 Performing local ad-hoc codesign..."
codesign --force --deep --sign - "${APP_DIR}"

echo "✅ Chippy.app successfully created at ${APP_DIR}"
