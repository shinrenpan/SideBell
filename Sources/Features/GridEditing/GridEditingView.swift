import SwiftUI

/// 編輯患者端的呼叫項目。只從患者端設定（兩段確認之後）進得來。
///
/// **是清單，不是格子**：用格子編輯格子等於把「觸發呼叫」與「調整設定」放在
/// 同一種介面裡，照顧者會不確定點下去會發生什麼。清單是一維的，天然適合
/// 排序與刪除。
struct GridEditingView: View {
    @Bindable var viewModel: GridEditingViewModel

    /// 新增／改名輸入中的名稱。屬於畫面的暫態，不進 ViewModel——
    /// 送出之後才是資料。
    @State private var draftTitle = ""
    @State private var isAddingItem = false
    @State private var renamingItem: GridEditingViewModel.EditItem?
    /// 拖曳與刪除**只在編輯模式生效**，因此需要讀得到目前的模式。
    @Environment(\.editMode) private var editMode
    /// 等待確認刪除的項目。刪除不可復原，因此是「立即生效」的唯一例外。
    @State private var pendingDeletion: GridEditingViewModel.EditItem?

    var body: some View {
        List {
            Section {
                ForEach(viewModel.state.items) { item in
                    row(item)
                        // 受保護的那一項不能被拖走。它是患者唯一保證叫得到人的
                        // 格子，而患者記住的是它的實體位置。
                        //
                        // 其餘的項目也**只在編輯模式**才能拖或刪：誤觸的代價
                        // 並不對稱——誤刪有確認對話框擋著，誤改順序卻沒有任何
                        // 攔阻，而患者記住的正是位置，他按錯格子時也沒辦法
                        // 告訴任何人。既然左上就有「編輯」，隨手一滑一按就能
                        // 改變患者看到的東西並不划算。
                        .moveDisabled(item.isProtected || !isEditing)
                        .deleteDisabled(item.isProtected || !isEditing)
                }
                .onMove { source, destination in
                    Task { await viewModel.doAction(.move(source, destination)) }
                }
                .onDelete { offsets in
                    // 不直接刪：刪除不可復原，是「立即生效」的唯一例外。
                    pendingDeletion = offsets.compactMap { offset in
                        viewModel.state.items.indices.contains(offset)
                            ? viewModel.state.items[offset] : nil
                    }
                    .first
                }
            } footer: {
                // 手勢沒有視覺提示，沒寫出來的功能等於不存在。
                // 刪除與排序都在「編輯」裡，因此指路指到那顆按鈕。
                Text("Tap an item to rename it. Use Edit to reorder or remove. Changes apply right away.")
            }

            if !viewModel.state.canAdd {
                // 說**為什麼**不能再加，而不是只把按鈕變灰。理由要講到患者
                // 身上：再加下去，多出來的格子他根本看不到。
                Section {
                    notice(
                        String(
                            localized:
                                "This screen fits \(viewModel.state.itemLimit) items. Any more would not be visible to the patient — remove one to make room."
                        ),
                        icon: "exclamationmark.triangle.fill"
                    )
                }
            } else if viewModel.state.isCrowded {
                // 只是提示，新增仍然可用。**照顧者才知道這個家需要什麼**，
                // 這裡只負責讓他知道代價，取捨由他做。
                //
                // icon 比上面那則弱一階（空心圓 vs 實心三角）：兩則都用最強的
                // 樣式，等於告訴照顧者「這兩件事一樣嚴重」，而其中一件只是建議。
                Section {
                    notice(
                        String(
                            localized:
                                "The more items there are, the longer the patient has to search for the one they want. Consider replacing one instead of adding another."
                        ),
                        icon: "eye.trianglebadge.exclamationmark"
                    )
                }
            }

            if let message = viewModel.state.failureMessage {
                Section { failureNotice(message) }
            }
        }
        .navigationTitle("Edit call items")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            editButton
            addButton
        }
        .task {
            await viewModel.doAction(.onAppear)
        }
        .alert("New item", isPresented: $isAddingItem) {
            nameField
            Button("Cancel", role: .cancel) { draftTitle = "" }
            Button("Add") {
                let title = draftTitle
                draftTitle = ""
                Task { await viewModel.doAction(.add(title)) }
            }
        } message: {
            Text("What should the patient be able to ask for?")
        }
        .alert("Rename", isPresented: isRenaming) {
            nameField
            Button("Cancel", role: .cancel) { draftTitle = "" }
            Button("Save") {
                guard let item = renamingItem else { return }
                let title = draftTitle
                draftTitle = ""
                Task { await viewModel.doAction(.rename(item.id, title)) }
            }
        }
        // 用 alert 而非 confirmationDialog：後者在 iPad 上是 popover，會 anchor
        // 到附加它的視圖——也就是整個 List，於是彈在畫面中央附近而不是使用者
        // 剛滑開的那一列，看起來像是對別的東西發問。alert 兩邊都置中，一致。
        .alert(deletionPrompt, isPresented: isConfirmingDeletion) {
            Button("Remove", role: .destructive) {
                guard let item = pendingDeletion else { return }
                pendingDeletion = nil
                Task { await viewModel.doAction(.delete(item.id)) }
            }
            Button("Keep", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("The patient will no longer be able to ask for this.")
        }
    }
}

// MARK: - 列

private extension GridEditingView {
    func row(_ item: GridEditingViewModel.EditItem) -> some View {
        Button {
            draftTitle = item.title
            renamingItem = item
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)

                if item.isProtected {
                    // 說明它為什麼與別人不同，而不只是長得不一樣。
                    // 放在標題底下當副標，而不是並排——並排會讓人以為
                    // 那串字是名稱的一部分。
                    Text("Always first, cannot be removed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        // `.plain` 是為了顏色：預設樣式會把 label 裡的**所有**文字染成 tint 色，
        // 連副標也一起變藍，於是它看起來像是可以點的另一個東西。
        // 整列仍然可點——可點的範圍由上面的 `contentShape` 決定。
        .buttonStyle(.plain)
    }
}

// MARK: - 元件

private extension GridEditingView {
    var nameField: some View {
        TextField("Name", text: $draftTitle)
            .textInputAutocapitalization(.never)
    }

    var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                draftTitle = ""
                isAddingItem = true
            } label: {
                Label("Add item", systemImage: "plus")
            }
            // 停用而不是讓他填完名稱才被拒——那等於讓他白做一次工。
            .disabled(!viewModel.state.canAdd)
        }
    }

    /// 排序用標準的編輯模式，而不是讓清單永遠可拖。
    ///
    /// 永遠可拖的代價是「點一下」與「按住拖」變得難以區分——照顧者想改名
    /// 卻不小心把格子搬了位置，而患者記住的正是位置。
    var editButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
        }
    }

    /// 一則說明。**顏色只給圖示，文字保持一般色**——整段塗成橘色會讓它讀起來
    /// 像錯誤，而其中一則其實只是建議。
    func notice(_ message: String, icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
            Spacer()
        }
    }

    /// 操作失敗。與上面兩則的差別是**它可以關掉**：那是使用者做過某件事的
    /// 結果，不是畫面的常態。
    func failureNotice(_ message: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
            Spacer()
            Button {
                Task { await viewModel.doAction(.dismissFailure) }
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    /// 改名對話框的開關。以「有沒有選中的項目」推導，避免兩個狀態各說各話。
    var isRenaming: Binding<Bool> {
        Binding(
            get: { renamingItem != nil },
            set: { if !$0 { renamingItem = nil } }
        )
    }

    var isConfirmingDeletion: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }

    /// 確認的問句帶上名稱——「要刪除嗎」與「要刪除『喝水』嗎」的差別，
    /// 是照顧者能不能發現自己滑錯了一列。
    var deletionPrompt: String {
        guard let title = pendingDeletion?.title else {
            return String(localized: "Remove this item?")
        }
        return String(localized: "Remove “\(title)”?")
    }
}

#if DEBUG
#Preview("編輯清單") {
    NavigationStack {
        GridEditingView(viewModel: .mock)
    }
}
#endif
