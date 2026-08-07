import UIKit

/// 患者端容器。
///
/// 只做導覽裝配，不持有任何畫面狀態——設定入口屬於主畫面的 toolbar，
/// 狀態歸該畫面的 ViewModel，導航經由 `onRoute` 交給 C 層。
///
/// 先前的版本把一顆 UIButton 疊在容器的 view 上，繞過了整個 MVVMC 結構：
/// 狀態管理落在容器裡、導航直接呼叫 AppRouter、按鈕還跟內容搶同一塊空間，
/// 實測時 VoiceOver 的聚焦框甚至把它和下方那一列框在一起。
///
/// 改用標準 toolbar 的代價是頂部多佔約 44pt——那正是先前 overlay 想省下的，
/// 但省法換來的是架構偏離與無障礙問題，不划算。
final class PatientHomeContainer: UINavigationController {
    init(callCenter: CallCenter, roleStore: RoleStore) {
        // 主畫面暫時沿用 W1 的傳輸驗證畫面，讓骨架改動後能立即確認
        // 傳輸行為沒有退化。正式的格子畫面就位後，整個 TransportPoC 目錄應刪除；
        // 設定入口以 `TwoStepConfirmButton` 元件的形式沿用，不需重寫。
        super.init(rootViewController: TransportPoCHostController(callCenter: callCenter))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
