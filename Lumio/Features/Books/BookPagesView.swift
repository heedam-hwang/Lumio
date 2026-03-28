import Observation
import PhotosUI
import SwiftData
import SwiftUI

struct BookPagesView: View {
    @Environment(\.modelContext) private var modelContext

    let book: Book

    @State private var editMode: EditMode = .inactive
    @State private var uploadCoordinator: BookPageUploadCoordinator
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editingPage: Page?
    @State private var editingPageTitle = ""
    @State private var showPageRenameAlert = false
    @State private var pendingPageDeletion: Page?
    @State private var showPageDeleteConfirmation = false
    @State private var saveErrorMessage: String?
    @State private var showSaveErrorAlert = false

    init(book: Book) {
        self.book = book
        _uploadCoordinator = State(initialValue: BookPageUploadCoordinator(book: book))
    }

    private let canvasColor = LumioColors.canvasWarm

    private var sortedPages: [Page] {
        book.pages.sorted(by: PageSorting.areInDisplayOrder)
    }

    private var isEditing: Bool {
        editMode == .active
    }

    var body: some View {
        @Bindable var uploadCoordinator = uploadCoordinator

        ZStack(alignment: .bottomTrailing) {
            canvasColor
                .ignoresSafeArea()

            if sortedPages.isEmpty {
                ContentUnavailableView {
                    Label("등록된 페이지가 없습니다", systemImage: "doc")
                } description: {
                    Text("이 화면에서 바로 페이지를 추가해 보세요.")
                }
            } else if isEditing {
                List {
                    ForEach(Array(sortedPages.enumerated()), id: \.element.id) { index, page in
                        BookPageRowView(
                            page: page,
                            subtitle: pageSubtitle(for: page),
                            showsTopDivider: index != 0,
                            isEditing: true,
                            onRename: { beginRenaming(page) },
                            onDelete: { confirmDelete(page) }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: movePages)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            } else {
                List {
                    ForEach(Array(sortedPages.enumerated()), id: \.element.id) { index, page in
                        NavigationLink(value: HomeRoute.page(bookID: book.id, pageID: page.id)) {
                            BookPageRowView(
                                page: page,
                                subtitle: pageSubtitle(for: page),
                                showsTopDivider: index != 0,
                                isEditing: false,
                                onRename: {},
                                onDelete: {}
                            )
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
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
                    Label("이 책에 페이지 추가", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .font(LumioTypography.floatingActionSymbol)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                    .background(Circle().fill(LumioColors.accentFill))
                    .lumioShadow(LumioShadows.floatingAction)
            }
            .accessibilityLabel("이 책에 페이지 추가")
            .accessibilityHint("카메라 또는 포토 라이브러리에서 현재 책에 페이지를 추가합니다.")
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .disabled(uploadCoordinator.isAnalyzingUpload)
            .zIndex(3)
        }
        .navigationTitle(book.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
        .overlay {
            if uploadCoordinator.isAnalyzingUpload {
                LoadingOverlayView(title: "문장/단어 감지 중")
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
        .sheet(isPresented: $uploadCoordinator.showQuickSaveSheet, onDismiss: uploadCoordinator.dismissQuickSaveSheet) {
            QuickSavePageSheet(
                pageTitle: $uploadCoordinator.customPageTitle,
                onCancel: {
                    uploadCoordinator.showQuickSaveSheet = false
                },
                onSave: {
                    uploadCoordinator.save(modelContext: modelContext)
                }
            )
            .presentationDetents([.medium])
        }
        .alert("페이지 제목 변경", isPresented: $showPageRenameAlert) {
            TextField("페이지 제목", text: $editingPageTitle)
            Button("취소", role: .cancel) {}
            Button("저장", action: saveEditedPageTitle)
        } message: {
            Text("페이지 목록에서 보이는 제목을 수정합니다.")
        }
        .confirmationDialog("페이지를 삭제할까요?", isPresented: $showPageDeleteConfirmation, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                if let pendingPageDeletion {
                    deletePage(pendingPageDeletion)
                }
                pendingPageDeletion = nil
            }
            Button("취소", role: .cancel) {
                pendingPageDeletion = nil
            }
        } message: {
            Text("삭제한 페이지는 복구할 수 없습니다.")
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert) {} message: {
            Text(saveErrorMessage ?? "데이터 저장에 실패했습니다.")
        }
        .alert("OCR 처리 실패", isPresented: $uploadCoordinator.showUploadErrorAlert) {} message: {
            Text(uploadCoordinator.uploadErrorMessage ?? "문장/단어 감지에 실패했습니다.")
        }
    }

    private func beginRenaming(_ page: Page) {
        editingPage = page
        editingPageTitle = page.title ?? ""
        showPageRenameAlert = true
    }

    private func confirmDelete(_ page: Page) {
        pendingPageDeletion = page
        showPageDeleteConfirmation = true
    }

    private func pageSubtitle(for page: Page) -> String {
        let firstSentence = page.sentences
            .sorted { $0.order < $1.order }
            .first?
            .text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let firstSentence, !firstSentence.isEmpty {
            return firstSentence
        }

        return page.isTextAnalyzed ? "감지된 첫 문장이 없습니다." : "문장 분석 중"
    }

    private func saveEditedPageTitle() {
        guard let editingPage else { return }

        let trimmed = editingPageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        editingPage.title = trimmed.isEmpty ? nil : trimmed

        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = "페이지 제목 저장에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    private func deletePage(_ page: Page) {
        modelContext.delete(page)

        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = "페이지 삭제에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    private func movePages(from source: IndexSet, to destination: Int) {
        var reorderedPages = sortedPages
        reorderedPages.move(fromOffsets: source, toOffset: destination)

        for (index, page) in reorderedPages.enumerated() {
            page.sortOrder = index + 1
        }

        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = "페이지 순서 저장에 실패했습니다."
            showSaveErrorAlert = true
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
