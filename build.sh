#!/usr/bin/env zsh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${1:-release}"
APP="$PROJECT_DIR/Ice.app"
APP_NAME="Ice"
ENTITLEMENTS="$PROJECT_DIR/Ice/Ice.entitlements"
VERSION="0.11.12"
BUILD="1117"
RESOURCE_BUNDLE_NAME=""

case "$CONFIG" in
    debug)
        SWIFT_ARGS=()
        ;;
    release)
        SWIFT_ARGS=(-c release)
        ;;
    build-only)
        swift build --package-path "$PROJECT_DIR"
        echo "Build complete (build-only)."
        exit 0
        ;;
    *)
        echo "Usage: ./build.sh [release|debug|build-only]"
        exit 1
        ;;
esac

swift build --package-path "$PROJECT_DIR" "${SWIFT_ARGS[@]}"

BIN_DIR="$(swift build --package-path "$PROJECT_DIR" "${SWIFT_ARGS[@]}" --show-bin-path)"
BIN="$BIN_DIR/$APP_NAME"
RESOURCE_BUNDLE_NAME="$(find "$BIN_DIR" -maxdepth 1 -name 'Ice_*.bundle' -print -quit || true)"
FRAMEWORK_SOURCE_DIR="$BIN_DIR"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"

cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/$APP_NAME" 2>/dev/null || true

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.jordanbaird.Ice</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 Jordan Baird</string>
    <key>SUFeedURL</key>
    <string>https://jordanbaird.github.io/ice-releases/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>3nfIGMOD8DALPE8vIdFo2tUOIVc2MVbzhc+2J9JLn+Q=</string>
</dict>
</plist>
EOF

if [[ -n "$RESOURCE_BUNDLE_NAME" ]]; then
    cp -R "$RESOURCE_BUNDLE_NAME" "$APP/Contents/Resources/"
fi

find "$FRAMEWORK_SOURCE_DIR" -maxdepth 1 -type d -name '*.framework' -exec cp -R {} "$APP/Contents/Frameworks/" \;
find "$FRAMEWORK_SOURCE_DIR" -maxdepth 1 -type d -name '*.bundle' ! -name 'Ice_*.bundle' -exec cp -R {} "$APP/Contents/Resources/" \;
find "$FRAMEWORK_SOURCE_DIR" -maxdepth 1 -type f \( -name '*.dylib' -o -name '*.so' \) -exec cp {} "$APP/Contents/Frameworks/" \;

xattr -cr "$APP"
codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$APP"

pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.3
open "$APP"
echo "$APP_NAME ($CONFIG) built and launched."
