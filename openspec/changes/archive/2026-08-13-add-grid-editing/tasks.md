## 1. 資料層（測試先行）

- [x] [P] 1.1 在 `Tests/PersistenceTests/GridItemStoreTests.swift` 補上失敗測試，涵蓋：首次種子產生**兩個**項目且第一個為受保護、新增項目後排在最後且產生唯一的 `commandCode`、更新標題、刪除非受保護項目成功、**刪除受保護項目擲出錯誤**、重新排序後受保護項目仍在第一、空白標題被拒、超過 100 位元組的標題被拒。驗證：測試存在且因尚未實作而失敗。
- [x] 1.2 依「`不舒服` 是受保護的項目：可改名、不可刪除、永遠第一格」為 `Sources/Core/Persistence/GridItemModel.swift` 加入受保護的布林欄位，滿足 `One item is protected so the patient is never left without a way to call`（Scenario: Protection is a property, not a name or a position）。驗證：以 grep 確認全專案判斷保護狀態時只讀該欄位，未出現以標題文字或索引位置推斷的程式碼。
- [x] 1.3 依「首次安裝只種兩個項目」修改 `Sources/Core/Persistence/GridItemStore.swift` 的種子內容為 `不舒服`（受保護）與 `喝水`，滿足 `grid-storage` 的 `A first launch is seeded with four default items`（已改寫為兩項）。驗證：刪除 App 重裝後患者端只出現兩格，且不舒服在第一格。
- [x] 1.4 依「`commandCode` 由系統產生，不出現在編輯畫面」與「編輯結果立即生效，不需要確認或套用」為 `GridItemStore` 加入新增、更新標題、刪除、重新排序四個操作，使 1.1 全數通過，滿足 `The caregiver can shape the grid to this household's needs` 與 `Editing takes effect immediately`。驗證：測試全綠；刪除受保護項目的請求擲出錯誤而非靜默忽略；新增產生的 `commandCode` 在 8 位元組 ASCII 內且不重複。

## 2. 編輯畫面

- [x] [P] 2.1 在 `Tests/GridEditingTests/GridEditingStateTests.swift` 撰寫失敗測試，以假 store 驅動，涵蓋：載入後依序呈現所有項目且受保護者在第一、新增後清單增加一列、改名後該列更新、刪除後該列消失、達上限時新增被拒且狀態可供畫面停用入口、空白與超長標題產生可讀的錯誤訊息。驗證：測試存在且因尚未實作而失敗。
- [x] 2.2 依「編輯畫面是清單，不是格子」在 `Sources/Features/GridEditing/` 建立四件套與 `GridEditingMocks.swift`，以 List 呈現項目並支援新增與改名，使 2.1 通過，滿足 `The caregiver can shape the grid to this household's needs`。驗證：測試全綠；新增流程只要求輸入名稱一個欄位。
- [x] 2.3 實作拖拽排序與受保護項目的限制，滿足 `One item is protected so the patient is never left without a way to call`（Scenario: The protected item stays first）：受保護項目無法被拖動，其他項目無法被放到它之前。驗證：實機上嘗試把任一項目拖到第一列會被彈回。
- [x] 2.4 依「編輯結果立即生效，不需要確認或套用」中「刪除是唯一的例外」實作刪除與其確認對話框，並確保受保護項目**沒有刪除入口**，滿足 `Editing takes effect immediately`（Scenario: Deleting is confirmed first）。驗證：受保護項目的列上沒有刪除手勢或按鈕；刪除其他項目時出現確認。
- [x] 2.5 依「數量上限在「新增」那一步擋，並說明原因」實作上限判斷，滿足 `Adding stops at the limit, with the reason stated`：達上限時停用新增入口並說明「再加就會有格子患者看不到」。驗證：以既有的版面演算法取得該裝置的上限；刪掉一項後新增重新可用。
- [x] 2.6 依「緊急等級不開放設定」確認新增流程不呈現任何緊急相關的選項，滿足 `Only the protected item raises an urgent call`。驗證：以 grep 確認 `Sources/Features/GridEditing/` 下無 `isUrgent` 的寫入路徑，新增的項目一律非緊急。

## 3. 入口

- [x] 3.1 於 `Sources/Features/RoleSettings/` 三件套加入「編輯呼叫項目」一列，並在 `Sources/App/AppRouter.swift` 加入開啟編輯畫面的轉場。驗證：該入口只出現在患者端的設定畫面（經由既有的兩段確認進入）；照顧者端設定分頁不受影響。

## 4. 既有文件與測試的更新

- [x] 4.1 更新 `docs/device-verification/w3-patient-grid.md` 中以「四格」描述畫面的段落（G1 首次啟動、G2 版面），改為兩格，並註明變更來自本 change。驗證：**預期**欄位不再以四格描述畫面，且 G1／G2 標記為待重驗；已完成的「實際結果」保留原文並逐條加註。

  > **驗證條件修正（2026-08-13）**：原本寫「以 grep 確認該檔無殘留的『四格』描述」，做不到也不該做——那份清單裡的「四格」大多出現在**已完成的驗證紀錄**（G1 的 2026-08-08 通過紀錄、G2 記載 iPad mini 排成 4×1 的缺陷史、G3／G5 的四則呼叫紀錄）。那些是當天的事實，改寫它們等於讓清單說謊，而 G2 那段缺陷史正是版面演算法為何要重寫的唯一憑據。因此只改**預期**，實際結果保留並註明要重驗什麼。
- [x] 4.2 依 W5（`add-localization`）建立的流程處理本 change 的字串：新增／改名／刪除的按鈕與提示、上限說明、標題驗證的錯誤訊息，一律寫成**英文**字面值且直接放在 `Text()` 或 `String(localized:)` 內，建置後以 `xcrun xcstringstool sync` 併回 catalog 並補繁中翻譯。**同時處理預設格子由四項縮為兩項所產生的 stale**：`Turn over` 與 `Bathroom` 兩個 key 將不再有使用點，須自 catalog 刪除（那是「功能已移除」那一類，可以直接刪；不要用 grep 判斷死活，會誤判註解）。驗證：stale 數為 0、缺翻譯數為 0；以 grep 確認 `Sources/Features/GridEditing/` 無中文字面值（註解與 `#Preview` 名稱除外）。

## 5. 驗證

- [x] 5.1 建立 `docs/device-verification/w7-grid-editing.md`，涵蓋首次安裝為兩格、新增後患者端出現該格、改名後患者端更新、刪除後消失、排序後患者端順序一致、受保護項目無刪除入口且無法拖動、受保護項目改名後仍受保護、達上限時的說明、以及空白與超長標題的拒絕，每項含前置條件、步驟、預期結果、實際結果與 OS 版本欄位。驗證：文件涵蓋本 change 全部實機驗收項目，逐項可獨立執行。
- [x] 5.2 執行並記錄編輯行為驗證：新增、改名、刪除、排序四種操作，每次都回到患者端格子確認畫面一致。驗證：清單中填入實際結果與 OS 版本。
- [x] 5.3 執行並記錄保護與上限驗證：受保護項目無法刪除與拖動、改名後仍受保護、達上限時新增被擋並說明原因、刪除一項後恢復可新增。驗證：清單中填入實際結果。
