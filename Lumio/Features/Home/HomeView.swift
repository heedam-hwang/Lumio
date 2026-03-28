import Observation
import PhotosUI
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Book.title)]) private var books: [Book]

    @State private var navigationPath: [HomeRoute] = []
    @State private var uploadCoordinator = HomeUploadCoordinator()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editingBook: Book?
    @State private var editingBookTitle = ""
    @State private var showBookRenameAlert = false
    @State private var persistenceErrorMessage: String?
    @State private var showPersistenceErrorAlert = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        @Bindable var uploadCoordinator = uploadCoordinator

        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                if books.isEmpty {
                    ContentUnavailableView {
                        Label("아직 등록된 책이 없습니다", systemImage: "book.closed")
                    } description: {
                        Text("오른쪽 아래 업로드 버튼으로 책 페이지를 추가해 보세요.")
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 18) {
                            ForEach(books) { book in
                                BookGridCardView(
                                    book: book,
                                    onRename: { beginRenaming(book) },
                                    onChangeCover: { imageData in
                                        saveBookCover(book: book, imageData: imageData)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 96)
                    }
                }

                if uploadCoordinator.showUploadSourceMenu {
                    DismissScrimButton(action: uploadCoordinator.dismissUploadSourceMenu)
                        .zIndex(1)

                    UploadSourceMenuView(
                        onCameraTap: uploadCoordinator.selectCamera,
                        onPhotoTap: uploadCoordinator.selectPhotoLibrary,
                        isCameraAvailable: UIImagePickerController.isSourceTypeAvailable(.camera)
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 86)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(2)
                }

                Button(action: uploadCoordinator.toggleUploadSourceMenu) {
                    Label("책 페이지 업로드", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.accentColor))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("책 페이지 업로드")
                .accessibilityHint("카메라 또는 포토 라이브러리에서 책 페이지를 추가합니다.")
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .disabled(uploadCoordinator.isAnalyzingUpload)
                .zIndex(3)
            }
            .navigationTitle("책 목록")
            .navigationDestination(for: HomeRoute.self) { route in
                destinationView(for: route)
            }
            .overlay {
                if uploadCoordinator.isAnalyzingUpload {
                    LoadingOverlayView(title: "문장/단어 감지 중")
                }
            }
        }
        .photosPicker(
            isPresented: $uploadCoordinator.showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadSelectedPhotoItem(newItem)
            selectedPhotoItem = nil
        }
        .fullScreenCover(isPresented: $uploadCoordinator.showCamera) {
            CameraPicker(onImagePicked: uploadCoordinator.cameraCaptured)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $uploadCoordinator.showSavePageSheet, onDismiss: uploadCoordinator.dismissSaveSheet) {
            SavePageSheet(
                books: books,
                pageTitle: $uploadCoordinator.customPageTitle,
                onCancel: {
                    uploadCoordinator.showSavePageSheet = false
                },
                onSave: { mode, selectedBook, newBookTitle in
                    uploadCoordinator.save(
                        mode: mode,
                        selectedBook: selectedBook,
                        newBookTitle: newBookTitle,
                        modelContext: modelContext
                    )
                }
            )
            .presentationDetents([.medium])
        }
        .alert("책 이름 변경", isPresented: $showBookRenameAlert) {
            TextField("책 이름", text: $editingBookTitle)
            Button("취소", role: .cancel) {}
            Button("저장", action: saveEditedBookTitle)
        } message: {
            Text("홈 화면의 책 분류 이름을 수정합니다.")
        }
        .alert("저장 실패", isPresented: $showPersistenceErrorAlert) {} message: {
            Text(persistenceErrorMessage ?? "데이터 저장에 실패했습니다.")
        }
        .alert("OCR 처리 실패", isPresented: $uploadCoordinator.showUploadErrorAlert) {} message: {
            Text(uploadCoordinator.uploadErrorMessage ?? "문장/단어 감지에 실패했습니다.")
        }
    }

    @ViewBuilder
    private func destinationView(for route: HomeRoute) -> some View {
        switch route {
        case let .book(bookID):
            if let book = books.first(where: { $0.id == bookID }) {
                BookPagesView(book: book)
            } else {
                ContentUnavailableView("책을 찾을 수 없습니다", systemImage: "book.closed")
            }

        case let .page(bookID, pageID):
            if let book = books.first(where: { $0.id == bookID }),
               let page = book.pages.first(where: { $0.id == pageID }) {
                PageDetailView(page: page)
            } else {
                ContentUnavailableView("페이지를 찾을 수 없습니다", systemImage: "doc")
            }
        }
    }

    private func beginRenaming(_ book: Book) {
        editingBook = book
        editingBookTitle = book.title
        showBookRenameAlert = true
    }

    private func saveEditedBookTitle() {
        let trimmed = editingBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let editingBook else { return }

        editingBook.title = trimmed

        do {
            try modelContext.save()
        } catch {
            persistenceErrorMessage = "책 이름 저장에 실패했습니다."
            showPersistenceErrorAlert = true
        }
    }

    private func saveBookCover(book: Book, imageData: Data) {
        book.coverImageData = imageData

        do {
            try modelContext.save()
        } catch {
            persistenceErrorMessage = "책 표지 저장에 실패했습니다."
            showPersistenceErrorAlert = true
        }
    }

    private func loadSelectedPhotoItem(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    uploadCoordinator.prepareImageForSave(data)
                } else {
                    uploadCoordinator.presentUploadError("선택한 사진을 읽을 수 없습니다.")
                }
            } catch {
                uploadCoordinator.presentUploadError("사진 불러오기에 실패했습니다. 다시 시도해 주세요.")
            }
        }
    }
}
