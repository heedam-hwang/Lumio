import PhotosUI
import SwiftUI

struct BookGridCardView: View {
    let book: Book
    let onRename: () -> Void
    let onChangeCover: (Data) -> Void
    let onDeleteCover: () -> Void
    let onDeleteBook: () -> Void

    @State private var coverSelection: PhotosPickerItem?
    @State private var showCoverPicker = false
    @State private var showDeleteCoverAlert = false

    var body: some View {
        NavigationLink(value: HomeRoute.book(book.id)) {
            VStack(alignment: .leading, spacing: 12) {
                BookCoverView(
                    placeholderPaletteSeed: book.placeholderPaletteSeed,
                    coverImageData: book.coverImageData
                )
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(LumioTypography.cardTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text("페이지 \(book.pages.count)개")
                            .font(LumioTypography.metadataAccent)
                            .foregroundStyle(LumioColors.accentFill)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(LumioColors.accentSoftFill)
                            )

                        Spacer(minLength: 0)

                        Menu {
                            Button {
                                showCoverPicker = true
                            } label: {
                                Label("표지 변경", systemImage: "photo")
                            }

                            if book.coverImageData != nil {
                                Button(role: .destructive) {
                                    showDeleteCoverAlert = true
                                } label: {
                                    Label("표지 삭제", systemImage: "trash")
                                }
                            }

                            Button(action: onRename) {
                                Label("책 이름 변경", systemImage: "pencil")
                            }

                            Button(role: .destructive, action: onDeleteBook) {
                                Label("책 삭제", systemImage: "trash.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(width: 18, height: 18)
                                .padding(11)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("책 옵션")
                    }
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
        .photosPicker(
            isPresented: $showCoverPicker,
            selection: $coverSelection,
            matching: .images
        )
        .alert("표지를 삭제할까요?", isPresented: $showDeleteCoverAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive, action: onDeleteCover)
        } message: {
            Text("삭제한 표지는 복구할 수 없습니다.")
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
