import SwiftUI

struct PageHeaderView: View {
    let page: Page
    let isEditing: Bool
    let onImageTap: () -> Void
    let onRenameTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let imageData = page.imageData,
               let uiImage = UIImage(data: imageData) {
                Button(action: onImageTap) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 92, height: 92)
                        .clipShape(.rect(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("원본 이미지 확대 보기")
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LumioColors.systemSecondarySurface)
                    .frame(width: 92, height: 92)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(page.title ?? "제목 없음")
                        .font(.title3.weight(.semibold))

                    if isEditing {
                        Button("이름 수정", action: onRenameTap)
                            .buttonStyle(.plain)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(page.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(LumioTypography.metadataAccent)
                    .foregroundStyle(LumioColors.accentFill)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LumioColors.elevatedCardSurface)
            )

            Spacer(minLength: 0)
        }
    }
}
