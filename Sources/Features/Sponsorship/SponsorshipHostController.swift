import SwiftUI
import UIKit

/// 贊助頁的 C 層。**只在照顧者端被建立**——患者端沒有任何路徑到得了這裡。
final class SponsorshipHostController: UIHostingController<SponsorshipView> {
    init(store: any SponsorshipProviding = SponsorshipStore()) {
        super.init(rootView: SponsorshipView(viewModel: SponsorshipViewModel(provider: store)))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
