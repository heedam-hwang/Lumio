import SwiftUI

struct BookPageRowView: View {
    let page: Page
    let subtitle: String
    let isEditing: Bool
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(page.title ?? "제목 없음")
                        .font(.headline)
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
                        .foregroundStyle(.red)
                        .accessibilityLabel("페이지 삭제")
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(page.createdAt.formatted(date: .numeric, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}
