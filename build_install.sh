#!/bin/bash
# ============================================================================
#  build_install.sh  ——  在「Mac + Xcode 15+」上把悬浮画板装到 iPad
# ============================================================================
#  用法（任选其一）：
#   1) 自动签名（需先在 Xcode 登录你的 Apple ID，免费账号即可，7 天有效）：
#        ./build_install.sh
#   2) 指定 Team ID（开发者账号）：
#        TEAM_ID=XXXXXXXXXX ./build_install.sh
#
#  说明：iOS App 必须在 macOS/Xcode 里编译 + 签名，无法在 Linux 环境产出 .ipa。
#        本脚本在 *你自己的 Mac* 上执行，负责 编译 → 生成 .app → 安装到已连接的 iPad。
# ============================================================================
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$PROJECT_DIR/OverlayBoard.xcodeproj"
SCHEME="OverlayBoard"
ARCHIVE_PATH="$PROJECT_DIR/build/OverlayBoard.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/OverlayBoard.app"

# 1) 确认 Xcode
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ 未找到 xcodebuild，请先安装 Xcode（App Store）并运行一次 xcodebuild -license accept"
  exit 1
fi
echo "✅ Xcode: $(xcodebuild -version | head -1)"

# 2) Team ID：优先用环境变量，否则尝试从本地钥匙串读取第一个开发者身份
TEAM="${TEAM_ID:-}"
if [ -z "$TEAM" ]; then
  TEAM=$(security find-identity -v -p codesigning 2>/dev/null \
         | grep -oE '\([A-Z0-9]{10,}\)' | head -1 | tr -d '()' || true)
fi
if [ -z "$TEAM" ]; then
  echo "⚠️  未检测到 Team ID。请用以下任一方式提供："
  echo "      TEAM_ID=你的TeamID ./build_install.sh"
  echo "   或在 Xcode 中打开工程 → Signing & Capabilities → 选 Team 后重新运行本脚本。"
  exit 1
fi
echo "🔑 使用 Team: $TEAM"

# 3) 把 Team 写进工程的 Debug/Release 配置（仅本地，不影响源码逻辑）
/usr/libexec/PlistBuddy -c "Set :objects:1A00000000000000000072:buildSettings:DEVELOPMENT_TEAM $TEAM" \
  "$PROJECT/project.pbxproj" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :objects:1A00000000000000000073:buildSettings:DEVELOPMENT_TEAM $TEAM" \
  "$PROJECT/project.pbxproj" 2>/dev/null || true

# 4) 编译并导出归档（针对真机 generic iOS device）
echo "📦 正在编译并归档（首次较慢，请耐心）..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$TEAM" \
  | tail -20

if [ ! -d "$APP_PATH" ]; then
  echo "❌ 归档失败，请检查上面的编译错误（常见：Team 未信任 / 设备未加入账号）。"
  exit 1
fi
echo "✅ 编译成功: $APP_PATH"

# 5) 安装到已连接的 iPad
DEVICE=$(xcrun devicectl list devices 2>/dev/null | grep -i ipad | head -1 | awk -F'(' '{print $2}' | tr -d ')') || true
if [ -n "$DEVICE" ]; then
  echo "📲 正在安装到 iPad ($DEVICE) ..."
  xcrun devicectl device install app --device "$DEVICE" "$APP_PATH" \
    && echo "🎉 安装完成！在 iPad 上打开「悬浮画板」即可。" \
    || echo "⚠️  安装失败（可能需要在 iPad 上信任开发者：设置 → 通用 → VPN与设备管理）。"
else
  echo "ℹ️  未检测到已连接的 iPad。请："
  echo "   1) 用数据线连接 iPad 并信任电脑；"
  echo "   2) 在 iPad 上 设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID；"
  echo "   3) 重新运行本脚本；或直接在 Xcode 里点 ▶ Run（更简单）。"
fi
