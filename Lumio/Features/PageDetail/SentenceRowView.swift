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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: onSentenceTap) {
                    Text("\(sentence.order)")
                        .font(LumioTypography.compactAction)
                        .foregroundStyle(isSelected ? .white : LumioColors.accentFill)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? LumioColors.accentFill : LumioColors.accentTokenFill)
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
                        .font(LumioTypography.compactAction)
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(LumioColors.accentSoftFill)
                        )

                    Button("삭제", action: onDeleteTap)
                        .font(LumioTypography.compactAction)
                        .foregroundStyle(LumioColors.destructiveFill)
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(LumioColors.destructiveSoftFill)
                        )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? LumioColors.accentSelectionFill : LumioColors.cardSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? LumioColors.accentSelectionStroke : LumioColors.cardStroke, lineWidth: 1)
        }
    }

    private func backgroundColor(for word: String) -> Color {
        if savedWords.contains(word) {
            return LumioColors.savedWordFill
        }
        if selectedWordText == word {
            return LumioColors.accentWordSelection
        }
        return .clear
    }
}
