import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class BookPageUploadCoordinator {
    let book: Book

    var showUploadSourceMenu = false
    var showCamera = false
    var showPhotoPicker = false
    var pendingImageData: Data?
    var showQuickSaveSheet = false
    var customPageTitle = ""
    var isAnalyzingUpload = false
    var uploadErrorMessage: String?
    var showUploadErrorAlert = false

    init(book: Book) {
        self.book = book
    }

    func toggleUploadSourceMenu() {
        showUploadSourceMenu.toggle()
    }

    func dismissUploadSourceMenu() {
        showUploadSourceMenu = false
    }

    func selectCamera() {
        showUploadSourceMenu = false
        showCamera = true
    }

    func selectPhotoLibrary() {
        showUploadSourceMenu = false
        showPhotoPicker = true
    }

    func cameraCaptured(_ imageData: Data) {
        prepareImageForSave(imageData)
    }

    func dismissQuickSaveSheet() {
        pendingImageData = nil
        customPageTitle = ""
    }

    func save(modelContext: ModelContext) {
        showQuickSaveSheet = false

        Task {
            await createPageAndAnalyze(modelContext: modelContext)
        }
    }

    func prepareImageForSave(_ imageData: Data) {
        pendingImageData = imageData
        showQuickSaveSheet = true
    }

    func presentUploadError(_ message: String) {
        uploadErrorMessage = message
        showUploadErrorAlert = true
    }

    private func createPageAndAnalyze(modelContext: ModelContext) async {
        guard let imageData = pendingImageData else { return }

        isAnalyzingUpload = true
        defer {
            isAnalyzingUpload = false
            pendingImageData = nil
        }

        let page = Page(
            title: PageTitleGenerator.resolvedTitle(input: customPageTitle),
            sortOrder: nextPageSortOrder(),
            createdAt: .now,
            imageData: imageData,
            book: book
        )
        modelContext.insert(page)

        do {
            try modelContext.save()
            try await PageTextAnalyzer.analyzeIfNeeded(page: page, context: modelContext)
        } catch {
            presentUploadError(error.localizedDescription)
        }
    }

    private func nextPageSortOrder() -> Int {
        let currentMax = book.pages.compactMap(\.sortOrder).max() ?? 0
        return currentMax + 1
    }

}
