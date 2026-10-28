#!/bin/bash
set -e

DIR="/Users/lu/geminicli/KaffelogicStudioNative"
cd "$DIR"

echo "=== 1. 使用 Swift 6 原生编译 (Release 优化) ==="
swift build -c release

APP_NAME="Kaffelogic Studio.app"
APP_DIR="$DIR/build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== 2. 创建 macOS App Bundle ==="
rm -rf "$DIR/build"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$DIR/.build/release/KaffelogicStudioNative" "$MACOS_DIR/KaffelogicStudioNative"
chmod +x "$MACOS_DIR/KaffelogicStudioNative"

cp "$DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "=== 3. 本地临时代码签名 ==="
codesign --force --deep --sign - "$APP_DIR"

DOWNLOADS="/Users/lu/Downloads"
mkdir -p "$DOWNLOADS"

echo "=== 4. 拷贝独立 App 到下载目录 ==="
rm -rf "$DOWNLOADS/$APP_NAME"
cp -R "$APP_DIR" "$DOWNLOADS/"
xattr -cr "$DOWNLOADS/$APP_NAME"

echo "=== 5. 生成标准 PKG 安装包 (Install Kaffelogic Studio 8.0.0 for Mac.pkg) ==="
PKG_PATH="$DOWNLOADS/Install Kaffelogic Studio 8.0.0 for Mac.pkg"
rm -f "$PKG_PATH"
pkgbuild --install-location "/Applications" \
         --component "$APP_DIR" \
         "$PKG_PATH"

echo "=== 6. 生成标准 DMG 磁盘映像安装包 (Kaffelogic Studio 8.0.0.dmg) ==="
DMG_STAGE="/tmp/kaffelogic_dmg_stage"
rm -rf "$DMG_STAGE"
mkdir -p "$DMG_STAGE"
cp -R "$APP_DIR" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

DMG_PATH="$DOWNLOADS/Kaffelogic Studio 8.0.0.dmg"
rm -f "$DMG_PATH"
hdiutil create -volname "Kaffelogic Studio" \
               -srcfolder "$DMG_STAGE" \
               -ov -format UDZO \
               "$DMG_PATH"
rm -rf "$DMG_STAGE"

echo "=== 全部安装包已成功推送到下载目录！ ==="
ls -lh "$DOWNLOADS"/*Kaffelogic*
