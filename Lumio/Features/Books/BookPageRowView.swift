import SwiftUI

struct BookPageRowView: View {
    let page: Page
    let subtitle: String
    let isEditing: Bool
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            pageThumbnail

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(page.title ?? "제목 없음")
                        .font(LumioTypography.cardTitle)
                        .lineLimit(1)

                    if isEditing {
                        Button(action: onRename) {
                            Label("페이지 이름 수정", systemImage: "pencil")
                                .labelStyle(.iconOnly)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("페이지 이름 수정")

                        Button(action: onDelete) {
                            Label("페이지 삭제", systemImage: "trash")
                                .labelStyle(.iconOnly)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(LumioColors.destructiveFill)
                        .accessibilityLabel("페이지 삭제")
                    }
                }

                Text(subtitle)
                    .font(LumioTypography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(page.createdAt.formatted(date: .numeric, time: .omitted))
                    .font(LumioTypography.metadataAccent)
                    .foregroundStyle(LumioColors.accentFill)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LumioColors.cardSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(LumioColors.cardStroke, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var pageThumbnail: some View {
        if let imageData = page.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 68)
                .clipShape(.rect(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(LumioColors.systemSecondarySurface)
                .frame(width: 52, height: 68)
                .overlay {
                    Image(systemName: "doc.text.image")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
