import SwiftUI

struct SentenceEditSheet: View {
    let draft: SentenceEditingDraft
    let onCancel: () -> Void
    let onSave: (String) -> Void

    @State private var text: String

    init(draft: SentenceEditingDraft, onCancel: @escaping () -> Void, onSave: @escaping (String) -> Void) {
        self.draft = draft
        self.onCancel = onCancel
        self.onSave = onSave
        _text = State(initialValue: draft.text)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("문장을 수정하면 페이지 화면과 페이지 목록의 첫 문장 표시가 바로 갱신됩니다.")
                    .font(LumioTypography.helperText)
                    .foregroundStyle(.secondary)

                TextField("문장", text: $text, axis: .vertical)
                    .lineLimit(5...)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LumioColors.systemSecondarySurface)
                    )

                Spacer()
            }
            .padding(20)
            .navigationTitle("문장 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(text)
                    }
                }
            }
        }
    }
}
