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
OUT="${OUT:-$(pwd)/build/screenshots}"
BUNDLE="com.shinrenpan.sidebell"
mkdir -p "$OUT"

# 裝置：名稱決定解析度，換機型前先確認尺寸符合 App Store 規格。
#   iPhone 17 Pro Max -> 1320x2868（歸在 APP_IPHONE_67）
#   iPad Pro 13-inch  -> 2064x2752（歸在 APP_IPAD_PRO_3GEN_129）
# Apple 沒有為 6.9"／13" 開獨立的 display type，兩者併入上一代的集合。
#
# 四個變數都可用環境變數覆寫，Shipaton 的截圖規格與 App Store 不同：
# 規則要求至少一張 1179x2556（iPhone 17 Pro，非 Max），且不得有裝置外框。
#   OUT=build/shipaton IPHONE_NAME="iPhone 17 Pro" LANGS=en DEVICES=iphone \
#     ./scripts/screenshots.sh
IPHONE_NAME="${IPHONE_NAME:-iPhone 17 Pro Max}"
IPAD_NAME="${IPAD_NAME:-iPad Pro 13-inch (M5)}"

read -r -a LANGS <<< "${LANGS:-en zh-Hant}"
read -r -a DEVICES <<< "${DEVICES:-iphone ipad}"
ROLES=(patient caregiver)

# 找不到時要回傳空字串讓呼叫端印出訊息，不能讓 grep 的非零離開碼配上
# `set -e` 把整支腳本靜默終止——那會看起來像什麼都沒發生。
device_id() {
  xcrun simctl list devices available \
    | { grep -F "$1 (" || true; } | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
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

  # 只固定電量與訊號，**不覆蓋時間**：畫面上的呼叫時間是實際跑出來的，狀態列
  # 若改成 Apple 慣用的 9:41，就會出現「現在 9:41，但這則呼叫來自 12:42」的
  # 矛盾。截圖裡的每個數字都該對得起來。
  #
  # 狀態列的**日期**跟著模擬器的系統語言走，-AppleLanguages 管不到（那只換
  # App）。英文截圖若出現中文日期，改該台模擬器的語言：
  #   xcrun simctl shutdown <UDID>
  #   PLIST=~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Library/Preferences/.GlobalPreferences.plist
  #   /usr/libexec/PlistBuddy -c "Delete :AppleLanguages" "$PLIST"
  #   /usr/libexec/PlistBuddy -c "Add :AppleLanguages array" "$PLIST"
  #   /usr/libexec/PlistBuddy -c "Add :AppleLanguages:0 string en-US" "$PLIST"
  # override 會留在裝置上直到 clear，不先清會疊加到上一次的設定。
  xcrun simctl status_bar "$dev" clear 2>/dev/null || true
  xcrun simctl status_bar "$dev" override \
    --batteryState charged --batteryLevel 100 --wifiBars 3 2>/dev/null || true

  xcrun simctl launch "$dev" "$BUNDLE" \
    -SideBellScreenshotMode -AppleLanguages "($lang)" -AppleLocale "$lang" >/dev/null 2>&1

  sleep 9   # 等畫面繪製完成，以及 ScreenshotTransport 插入示範呼叫
  xcrun simctl io "$dev" screenshot --type=png "$OUT/${tag}-${role}-${lang}.png" >/dev/null 2>&1
  echo "  ${tag}-${role}-${lang}.png"
}

for tag in "${DEVICES[@]}"; do
  case "$tag" in
    iphone) name="$IPHONE_NAME" ;;
    ipad)   name="$IPAD_NAME" ;;
    *)      echo "未知的裝置代號：${tag}（可用 iphone / ipad）" >&2; exit 1 ;;
  esac
  dev="$(device_id "$name")"

  if [ -z "$dev" ]; then
    echo "找不到模擬器：$name" >&2
    exit 1
  fi

  echo "== ${tag}（${name}）=="
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
