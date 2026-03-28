import PhotosUI
import SwiftUI

struct BookGridCardView: View {
    let book: Book
    let onRename: () -> Void
    let onChangeCover: (Data) -> Void

    @State private var coverSelection: PhotosPickerItem?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: HomeRoute.book(book.id)) {
                VStack(alignment: .leading, spacing: 12) {
                    BookCoverView(coverImageData: book.coverImageData)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(LumioTypography.cardTitle)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text("페이지 \(book.pages.count)개")
                            .font(LumioTypography.metadataAccent)
                            .foregroundStyle(LumioColors.accentFill)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(LumioColors.accentSoftFill)
                            )
                    }
                    .padding(.horizontal, 2)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(LumioColors.softCardSurface)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(LumioColors.softCardStroke, lineWidth: 1)
                }
                .lumioShadow(LumioShadows.card)
            }
            .buttonStyle(.plain)
            .accessibilityHint("선택하면 책의 페이지 목록으로 이동합니다.")

            Menu("책 옵션", systemImage: "ellipsis.circle") {
                PhotosPicker(selection: $coverSelection, matching: .images) {
                    Label("표지 변경", systemImage: "photo")
                }

                Button(action: onRename) {
                    Label("책 이름 변경", systemImage: "pencil")
                }
            }
            .labelStyle(.iconOnly)
            .padding(12)
            .background(.ultraThinMaterial, in: Circle())
            .padding(10)
        }
        .onChange(of: coverSelection) { _, newItem in
            guard let newItem else { return }

            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        onChangeCover(data)
                    }
                    coverSelection = nil
                } catch {
                    coverSelection = nil
                }
            }
        }
    }
}
