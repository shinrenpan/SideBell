#!/bin/bash
#
# 產出 App Store 截圖：兩個裝置 × 兩種語言 × 兩個角色，共 8 張。
#
# 為什麼需要這支腳本，而不是拿實機截圖：
#
# 1. 模擬器的原生解析度**正好**是 App Store 要求的尺寸（iPhone 6.9" 與
#    iPad 13"）。實機截圖反而要縮放，iPad 尤其對不上長寬比——iPad mini 的
#    0.657 與 13 吋的 0.75 差太多，等比縮放會留下大片黑邊。
# 2. 模擬器沒有 CoreBluetooth，連線狀態永遠停在「未連線」、照顧者端清單
#    永遠是空的。那是模擬器的限制，不是產品的樣子，但商店截圖若照實拍，
#    看的人只會認為這個 App 壞了。`ScreenshotTransport` 就是為此存在。
#
# 用法：./scripts/screenshots.sh
# 產出：build/screenshots/（已列入 .gitignore）
#
set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT="$(pwd)/SideBell.xcodeproj"
OUT="$(pwd)/build/screenshots"
BUNDLE="com.shinrenpan.sidebell"
mkdir -p "$OUT"

# 裝置：名稱決定解析度，換機型前先確認尺寸符合 App Store 規格。
#   iPhone 17 Pro Max -> 1320x2868（歸在 APP_IPHONE_67）
#   iPad Pro 13-inch  -> 2064x2752（歸在 APP_IPAD_PRO_3GEN_129）
# Apple 沒有為 6.9"／13" 開獨立的 display type，兩者併入上一代的集合。
IPHONE_NAME="iPhone 17 Pro Max"
IPAD_NAME="iPad Pro 13-inch (M5)"

LANGS=(en zh-Hant)
ROLES=(patient caregiver)

device_id() {
  xcrun simctl list devices available \
    | grep -F "$1 (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

shoot() {
  local dev="$1" tag="$2" lang="$3" role="$4" app="$5"

  xcrun simctl terminate "$dev" "$BUNDLE" 2>/dev/null || true
  # 每次重裝，不是多餘的：格子項目是資料庫裡的種子資料，以**第一次啟動時**
  # 的語言寫入，之後切語言不會跟著變（那是對的產品行為——使用者改過的名稱
  # 不該被語言覆蓋）。要讓各語言的截圖顯示對應文字，只能清掉資料庫重種。
  xcrun simctl uninstall "$dev" "$BUNDLE" 2>/dev/null || true
  sleep 2
  xcrun simctl install "$dev" "$app"

  # 跳過首次啟動的免責聲明與角色選擇，直接進到要拍的畫面。
  xcrun simctl spawn "$dev" defaults write "$BUNDLE" \
    "com.shinrenpan.sidebell.disclaimerAcknowledged" -bool true
  xcrun simctl spawn "$dev" defaults write "$BUNDLE" \
    "com.shinrenpan.sidebell.role" -string "$role"

  xcrun simctl launch "$dev" "$BUNDLE" \
    -SideBellScreenshotMode -AppleLanguages "($lang)" -AppleLocale "$lang" >/dev/null 2>&1

  sleep 9   # 等畫面繪製完成，以及 ScreenshotTransport 插入示範呼叫
  xcrun simctl io "$dev" screenshot --type=png "$OUT/${tag}-${role}-${lang}.png" >/dev/null 2>&1
  echo "  ${tag}-${role}-${lang}.png"
}

for entry in "iphone|$IPHONE_NAME" "ipad|$IPAD_NAME"; do
  tag="${entry%%|*}"
  name="${entry#*|}"
  dev="$(device_id "$name")"

  if [ -z "$dev" ]; then
    echo "找不到模擬器：$name" >&2
    exit 1
  fi

  echo "== $tag（$name）=="
  xcrun simctl boot "$dev" 2>/dev/null || true
  sleep 20

  # Homebrew 的 rsync 會讓 Xcode 的部分流程失敗，PATH 收乾淨比較保險。
  env PATH=/usr/bin:/bin:/usr/sbin:/sbin xcodebuild \
    -project "$PROJECT" -scheme SideBell -configuration Debug \
    -destination "platform=iOS Simulator,name=$name" build 2>&1 | grep -E "^\*\* BUILD" || true

  app="$(ls -td ~/Library/Developer/Xcode/DerivedData/SideBell-*/Build/Products/Debug-iphonesimulator/SideBell.app | head -1)"

  for lang in "${LANGS[@]}"; do
    for role in "${ROLES[@]}"; do
      shoot "$dev" "$tag" "$lang" "$role" "$app"
    done
  done
done

echo
echo "產出於 $OUT"
for f in "$OUT"/*.png; do
  echo "  $(basename "$f"): $(sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | tail -2 | tr -d '\n ' | sed 's/pixelWidth:/ /;s/pixelHeight:/ x /')"
done
