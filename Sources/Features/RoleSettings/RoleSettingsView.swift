import SwiftUI

struct RoleSettingsView: View {
    @Bindable var viewModel: RoleSettingsViewModel

    var body: some View {
        List {
            Section("目前角色") {
                LabeledContent("角色", value: roleText)
            }

            Section {
                Button("切換角色", role: .destructive) {
                    Task { await viewModel.doAction(.switchRole) }
                }
                .accessibilityHint("離開目前角色並回到首頁，可重新選擇患者端或照顧者端")
            } footer: {
                Text("切換角色會停止目前的連線。")
            }
        }
        .navigationTitle("設定")
        .task {
            await viewModel.doAction(.onAppear)
        }
    }
}

// MARK: - 私有

private extension RoleSettingsView {
    var roleText: String {
        switch viewModel.state.role {
        case .unselected: "未選擇"
        case .patient: "患者端"
        case .caregiver: "照顧者端"
        }
    }
}
