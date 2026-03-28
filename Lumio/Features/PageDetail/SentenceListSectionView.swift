import SwiftUI

struct SentenceListSectionView: View {
    let sentences: [SentenceItem]
    let pageIsTextAnalyzed: Bool
    let selectedSentenceID: UUID?
    let isEditing: Bool
    let selectedWordText: String?
    let savedWords: Set<String>
    let onSentenceTap: (SentenceItem) -> Void
    let onEditTap: (SentenceItem) -> Void
    let onWordTap: (String) -> Void
    let onDeleteTap: (SentenceItem) -> Void
    let onMoveUpTap: ((SentenceItem) -> Void)?
    let onMoveDownTap: ((SentenceItem) -> Void)?

    var body: some View {
        Section("문장") {
            if sentences.isEmpty {
                Text(pageIsTextAnalyzed ? "감지된 문장이 없습니다." : "문장 데이터를 준비 중입니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sentences) { sentence in
                    SentenceRowView(
                        sentence: sentence,
                        isSelected: selectedSentenceID == sentence.id,
                        isEditing: isEditing,
                        selectedWordText: selectedWordText,
                        savedWords: savedWords,
                        onSentenceTap: { onSentenceTap(sentence) },
                        onEditTap: { onEditTap(sentence) },
                        onWordTap: onWordTap,
                        onDeleteTap: { onDeleteTap(sentence) },
                        onMoveUpTap: onMoveUpTap.map { handler in { handler(sentence) } },
                        onMoveDownTap: onMoveDownTap.map { handler in { handler(sentence) } }
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                }
            }
        }
    }
}
