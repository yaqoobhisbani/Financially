#!/usr/bin/env bash
set -euo pipefail

# Builds an UNSIGNED .ipa for Financially.
#
# This does not archive/export via Xcode's distribution flow (which requires
# a provisioning profile fetched from the Apple Developer Portal). Instead it
# builds the app for a generic iOS device with code signing disabled, then
# manually assembles the Payload/ structure the .ipa format requires.
#
# The resulting IPA is NOT signed and cannot be installed as-is — it must be
# re-signed (Xcode, AltStore, Sideloadly, or your own signing pipeline)
# before it can run on a device.
#
# Usage: scripts/build_unsigned_ipa.sh [CONFIGURATION]
#   CONFIGURATION defaults to Release.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

SCHEME="Financially"
PROJECT="Financially.xcodeproj"
CONFIGURATION="${1:-Release}"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
PAYLOAD_DIR="$BUILD_DIR/Payload"

VERSION="$(grep -m1 'MARKETING_VERSION' "$PROJECT/project.pbxproj" | sed -E 's/.*= *([0-9A-Za-z.]+);.*/\1/')"
IPA_NAME="Financially-${VERSION:-unversioned}-unsigned.ipa"
IPA_PATH="$BUILD_DIR/$IPA_NAME"

echo "==> Cleaning"
rm -rf "$BUILD_DIR"
xcodebuild clean \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION"

echo "==> Building unsigned for a generic iOS device (configuration: $CONFIGURATION)"
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  AD_HOC_CODE_SIGNING_ALLOWED=NO

APP_PATH="$DERIVED_DATA_DIR/Build/Products/${CONFIGURATION}-iphoneos/${SCHEME}.app"
if [ ! -d "$APP_PATH" ]; then
  echo "error: expected .app not found at $APP_PATH" >&2
  exit 1
fi

echo "==> Packaging Payload/"
rm -rf "$PAYLOAD_DIR"
mkdir -p "$PAYLOAD_DIR"
cp -R "$APP_PATH" "$PAYLOAD_DIR/"

echo "==> Zipping IPA"
rm -f "$IPA_PATH"
(cd "$BUILD_DIR" && zip -rqy "$IPA_NAME" "Payload")

echo "==> Done"
echo "Unsigned IPA: $IPA_PATH"
echo
echo "NOTE: this IPA is unsigned and cannot be installed as-is — it must be"
echo "re-signed before it will run on a device."
