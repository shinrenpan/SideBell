# 教學截圖清單

`shinrenpan.github.io/static/SideBell/guide/` 這份教學用的實機截圖。
中英兩版都已完成（2026-08-29）：`img/zhTW/` 26 張、`img/en/` 25 張。
本清單保留下來，是為了日後 UI 改版需要重拍時，知道要拍哪些畫面、以及有哪些坑。

**檔名兩邊必須一致**——HTML 只換語言目錄，檔名不變。

## 拍攝前

1. **兩台裝置的系統語言改成英文**
   設定 → 一般 → 語言與地區 → iPhone/iPad 語言。

   系統語言決定的不只是 iOS 介面，還包括**權限對話框**與**狀態列日期**。
   `-AppleLanguages` 那類 App 層的設定管不到它們。

2. **刪除 SideBell 再重裝**

   這一步不能省。呼叫項目是**第一次啟動時**依當下語言寫入資料庫的種子資料，
   之後切換語言不會跟著變（那是對的產品行為——使用者改過的名稱不該被語言
   覆蓋）。不重裝的話，畫面會是英文介面配上「不舒服」「喝水」。

3. **關掉會出現在狀態列的干擾**：專注模式、低電量模式、錄影指示。

## 患者端（iPad，14 張）

| 檔名 | 畫面 |
|---|---|
| `p-01-disclaimer.png` | 首次啟動，**尚未勾選**。角色卡片是灰的，橘字提示可見 |
| `p-02-bluetooth.png` | 勾選當下跳出的藍牙權限對話框 |
| `p-01b-checked.png` | **已勾選**。核取方塊與橘字消失，角色卡片變藍 |
| `p-03-connected.png` | 主畫面，兩格（Discomfort / Water），左上角 Connected |
| `p-06-tap-again.png` | 按過一次「Settings」，右上角顯示橘色的「Tap again」 |
| `p-07-settings.png` | 設定頁：Role / Edit call items / Switch role |
| `p-08-edit-items.png` | 編輯項目清單，兩項 |
| `p-10-add-item.png` | 新增對話框，輸入框內已打好 `Turn over`，鍵盤可見 |
| `p-11-items-three.png` | 編輯項目清單，三項 |
| `p-09-edit-mode.png` | 編輯模式，紅色減號與拖曳把手；Discomfort 沒有減號 |
| `p-12-grid-three.png` | 主畫面變三格 |
| `p-04-waiting.png` | 某一格下方顯示 Waiting |
| `p-05-acknowledged.png` | 某一格下方顯示 Acknowledged |
| `p-13-no-response.png` | **非緊急**項目下方顯示 No response（等滿三分鐘） |

## 照顧者端（iPhone，11 張）

| 檔名 | 畫面 |
|---|---|
| `c-01-disclaimer.png` | 首次啟動，尚未勾選 |
| `c-02-bluetooth.png` | 藍牙權限對話框 |
| `c-03-notifications.png` | 通知權限對話框（選完角色、進入清單後才跳） |
| `c-04-disconnected.png` | 呼叫清單，橘色 Not connected |
| `c-05-connected.png` | 呼叫清單，綠色 Connected |
| `c-10-lockscreen.png` | **鎖定畫面**上的通知。狀態列請保持**靜音圖示可見** |
| `c-12-banner.png` | 主畫面或其他 App 上的橫幅通知 |
| `c-06-call-received.png` | 清單中有一則呼叫，右側是藍色的 **Got it** 按鈕 |
| `c-07-acknowledged.png` | 同一則按下之後，變成綠色勾 |
| `c-11-call-list.png` | 清單同時有 **Acknowledged 與 No response**，緊急項目左側有紅色警示圖示 |
| `c-08-settings.png` | 設定頁：Role / Support the developer / Switch role |

## 拍完之後

```bash
# 縮圖並放進網站（iPad 744 寬、iPhone 590 寬）
DST=~/Documents/github/shinrenpan.github.io/static/SideBell/guide/img/en
mkdir -p "$DST"
# 依上表逐一 sips --resampleWidth <744|590> <來源> --out "$DST/<檔名>"
```

新增語言時，記得同步開通兩處的語言連結：

- `static/SideBell/guide/<lang>/index.html` 頂端的語言列
- `static/SideBell/index.html` 的教學那一行

## 為什麼沒有用模擬器產

`scripts/screenshots.sh` 能產主畫面，但教學需要的是**權限對話框、鎖定畫面
通知、系統鍵盤**這些模擬器做不出來或不真實的畫面。而且模擬器沒有藍牙，
連線狀態得靠 `ScreenshotTransport` 假造——商店截圖可以，教學不行：教學的
價值就在於它拍的是使用者真的會看到的東西。
