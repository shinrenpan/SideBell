import SwiftUI

struct RoleSettingsView: View {
    @Bindable var viewModel: RoleSettingsViewModel

    var body: some View {
        List {
            Section("Current role") {
                LabeledContent("Role", value: roleText)
            }

            if viewModel.state.showsSponsorship {
                Section {
                    Button {
                        Task { await viewModel.doAction(.openSponsorship) }
                    } label: {
                        LabeledContent {
                            // 徽章是純裝飾，沒有任何功能掛在它上面。
                            if viewModel.state.hasSupported {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.pink)
                                    .accessibilityLabel(Text("You have supported the developer"))
                            }
                        } label: {
                            Text("Support the developer")
                        }
                    }
                } footer: {
                    Text("Supporting unlocks nothing. Every feature works the same either way.")
                }
            }

            Section {
                Button("Switch role", role: .destructive) {
                    Task { await viewModel.doAction(.switchRole) }
                }
                .accessibilityHint(Text("Leaves this role and returns to the home screen, where you can choose Patient or Caregiver again"))
            } footer: {
                Text("Switching roles stops the current connection.")
            }
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.doAction(.onAppear)
        }
    }
}

// MARK: - 私有

private extension RoleSettingsView {
    var roleText: String {
        switch viewModel.state.role {
        case .unselected: String(localized: "Not selected")
        case .patient: String(localized: "Patient")
        case .caregiver: String(localized: "Caregiver")
        }
    }
}
