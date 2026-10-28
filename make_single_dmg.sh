#!/bin/bash
set -e

DIR="/Users/lu/geminicli/KaffelogicStudioNative"
cd "$DIR"

echo "=== 1. 使用 Swift 6 原生编译 (Release 优化构建) ==="
swift build -c release

APP_NAME="Kaffelogic Studio.app"
APP_DIR="$DIR/build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== 2. 创建 macOS App Bundle 架构 ==="
rm -rf "$DIR/build"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$DIR/.build/release/KaffelogicStudioNative" "$MACOS_DIR/KaffelogicStudioNative"
chmod +x "$MACOS_DIR/KaffelogicStudioNative"

cp "$DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# 拷贝本地化资源
if [ -d "$DIR/Resources/zh-Hans.lproj" ]; then
    cp -R "$DIR/Resources/zh-Hans.lproj" "$RESOURCES_DIR/"
fi

echo "=== 3. 本地代码自签名 ==="
codesign --force --deep --sign - "$APP_DIR"

DOWNLOADS="/Users/lu/Downloads"
mkdir -p "$DOWNLOADS"

echo "=== 4. 清理旧安装包并生成唯一标准 DMG 安装包 ==="
DMG_STAGE="/tmp/kaffelogic_dmg_final"
rm -rf "$DMG_STAGE"
mkdir -p "$DMG_STAGE"
cp -R "$APP_DIR" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

DMG_PATH="$DOWNLOADS/Kaffelogic Studio.dmg"
rm -f "$DMG_PATH"
rm -f "$DOWNLOADS"/Install*Kaffelogic*.pkg
rm -f "$DOWNLOADS"/Kaffelogic*Studio*.dmg
rm -rf "$DOWNLOADS/$APP_NAME"

hdiutil create -volname "Kaffelogic Studio" \
               -srcfolder "$DMG_STAGE" \
               -ov -format UDZO \
               "$DMG_PATH"

rm -rf "$DMG_STAGE"

echo "=== 构建完成！下载目录已更新为唯一 DMG 安装包 ==="
ls -lh "$DOWNLOADS"/*Kaffelogic*
