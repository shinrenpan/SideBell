import Foundation
import SwiftData

/// 應用程式唯一的資料容器。
///
/// 患者端與照顧者端共用同一個容器：本產品是單一 App 二合一角色，
/// 角色可在設定頁切換，拆成兩個容器只會讓切換時多一層拆裝而換不到好處。
///
/// ⚠️ 建立失敗時**刻意直接崩潰**，不降級為空容器。一片空白的格子對患者
/// 而言是「我的求助按鈕全部消失了」——那比當場崩潰更危險，因為他會以為
/// 系統還能用。
nonisolated enum SideBellModelContainer {
    static func make() -> ModelContainer {
        do {
            return try ModelContainer(for: GridItemModel.self)
        } catch {
            fatalError("無法建立資料容器：\(error)")
        }
    }
}
