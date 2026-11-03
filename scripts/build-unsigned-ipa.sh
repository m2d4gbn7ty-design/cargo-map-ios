#!/usr/bin/env bash
# 在 macOS 上把 CustomApp 编译成「未签名」的 IPA。
# 未签名 IPA 本身不能直接装，需要用 Sideloadly / AltStore 用自己的
# Apple ID（或开发者证书）重新签名后安装。
set -euo pipefail

PROJECT="CustomApp.xcodeproj"
SCHEME="CustomApp"
CONFIG="Release"
SDK="iphoneos"
BUILD_DIR="$PWD/build"
OUT_DIR="$PWD/out"
IPA_NAME="${SCHEME}-unsigned.ipa"

echo "==> [1/3] 生成 Xcode 工程 (xcodegen)"
xcodegen generate --spec project.yml
xcodebuild -list -project "$PROJECT" || true

echo "==> [2/3] 编译（关闭签名）"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -sdk "$SDK" \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  EXPANDED_CODE_SIGN_IDENTITY="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  DEVELOPMENT_TEAM="" \
  build

APP_PATH="$BUILD_DIR/Build/Products/${CONFIG}-${SDK}/${SCHEME}.app"
if [ ! -d "$APP_PATH" ]; then
  echo "!! 没找到构建产物: $APP_PATH" >&2
  find "$BUILD_DIR/Build/Products" -maxdepth 2 -name "*.app" -print 2>/dev/null || true
  exit 1
fi

echo "==> [3/3] 打包 IPA"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/Payload"
cp -R "$APP_PATH" "$OUT_DIR/Payload/"
(cd "$OUT_DIR" && zip -qry "$IPA_NAME" Payload)

echo "==> 完成: $OUT_DIR/$IPA_NAME"
