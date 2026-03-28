import SwiftUI

struct SentenceRowView: View {
    let sentence: SentenceItem
    let isSelected: Bool
    let isEditing: Bool
    let selectedWordText: String?
    let savedWords: Set<String>
    let onSentenceTap: () -> Void
    let onEditTap: () -> Void
    let onWordTap: (String) -> Void
    let onDeleteTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: onSentenceTap) {
                    Text("\(sentence.order)")
                        .font(.caption.bold())
                        .foregroundStyle(isSelected ? .white : Color.accentColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)

                FlowWrapLayout(spacing: 4, lineSpacing: 6) {
                    ForEach(SentenceToken.build(from: sentence.text)) { token in
                        if token.isWord {
                            Button {
                                guard !isEditing else { return }
                                onWordTap(token.normalized)
                            } label: {
                                Text(token.text)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(backgroundColor(for: token.normalized))
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, token.trailingSpacing)
                        } else {
                            Text(token.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding(.trailing, token.trailingSpacing)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()

                if isEditing {
                    Button("수정", action: onEditTap)
                        .font(.caption.bold())
                        .buttonStyle(.borderless)

                    Button("삭제", action: onDeleteTap)
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .buttonStyle(.borderless)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
        )
    }

    private func backgroundColor(for word: String) -> Color {
        if savedWords.contains(word) {
            return .yellow.opacity(0.55)
        }
        if selectedWordText == word {
            return Color.accentColor.opacity(0.2)
        }
        return .clear
    }
}
