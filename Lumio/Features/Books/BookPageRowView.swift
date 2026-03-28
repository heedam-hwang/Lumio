import SwiftUI

struct BookPageRowView: View {
    let page: Page
    let subtitle: String
    let showsTopDivider: Bool
    let isEditing: Bool
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsTopDivider {
                Divider()
            }

            HStack(alignment: .top, spacing: 10) {
                pageThumbnail

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(page.title ?? "제목 없음")
                            .font(LumioTypography.cardTitle)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        if isEditing {
                            Button("이름 수정", action: onRename)
                                .buttonStyle(.borderless)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Button("삭제", role: .destructive, action: onDelete)
                                .buttonStyle(.borderless)
                                .font(.caption.weight(.semibold))
                        }
                    }

                    Text(subtitle)
                        .font(LumioTypography.bodySecondary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(page.createdAt.formatted(date: .numeric, time: .omitted))
                        .font(LumioTypography.metadataAccent)
                        .foregroundStyle(.secondary)
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
