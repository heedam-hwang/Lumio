import SwiftUI

struct QuickSavePageSheet: View {
    @Binding var pageTitle: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("페이지 이름") {
                    TextField("페이지 이름 (선택)", text: $pageTitle)

                    Text("입력하지 않으면 현재 시간을 기준으로 자동 생성됩니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("페이지 저장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: onSave)
                }
            }
        }
    }
}
