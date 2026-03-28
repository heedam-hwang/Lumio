import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class HomeUploadCoordinator {
    var showUploadSourceMenu = false
    var showCamera = false
    var showPhotoPicker = false
    var pendingImageData: Data?
    var showSavePageSheet = false
    var isAnalyzingUpload = false
    var uploadErrorMessage: String?
    var showUploadErrorAlert = false
    var customPageTitle = ""

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

    func dismissSaveSheet() {
        pendingImageData = nil
        customPageTitle = ""
    }

    func save(
        mode: BookClassificationMode,
        selectedBook: Book?,
        newBookTitle: String,
        modelContext: ModelContext
    ) {
        showSavePageSheet = false

        Task {
            await createPageAndAnalyze(
                mode: mode,
                selectedBook: selectedBook,
                newBookTitle: newBookTitle,
                modelContext: modelContext
            )
        }
    }

    func resolveTargetBook(
        mode: BookClassificationMode,
        selectedBook: Book?,
        newBookTitle: String,
        modelContext: ModelContext
    ) -> Book {
        switch mode {
        case .existing:
            if let selectedBook {
                return selectedBook
            }
            return fetchOrCreateUnclassifiedBook(modelContext: modelContext)

        case .new:
            let trimmed = newBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return fetchOrCreateUnclassifiedBook(modelContext: modelContext)
            }

            let createdBook = Book(title: trimmed)
            modelContext.insert(createdBook)
            return createdBook

        case .unclassified:
            return fetchOrCreateUnclassifiedBook(modelContext: modelContext)
        }
    }

    func prepareImageForSave(_ imageData: Data) {
        pendingImageData = imageData
        showSavePageSheet = true
    }

    func presentUploadError(_ message: String) {
        uploadErrorMessage = message
        showUploadErrorAlert = true
    }

    private func createPageAndAnalyze(
        mode: BookClassificationMode,
        selectedBook: Book?,
        newBookTitle: String,
        modelContext: ModelContext
    ) async {
        guard let imageData = pendingImageData else { return }

        isAnalyzingUpload = true
        defer {
            isAnalyzingUpload = false
            pendingImageData = nil
        }

        let targetBook = resolveTargetBook(
            mode: mode,
            selectedBook: selectedBook,
            newBookTitle: newBookTitle,
            modelContext: modelContext
        )

        let page = Page(
            title: PageTitleGenerator.resolvedTitle(input: customPageTitle),
            sortOrder: nextPageSortOrder(in: targetBook),
            createdAt: .now,
            imageData: imageData,
            book: targetBook
        )
        modelContext.insert(page)

        do {
            try modelContext.save()
            try await PageTextAnalyzer.analyzeIfNeeded(page: page, context: modelContext)
        } catch {
            presentUploadError(error.localizedDescription)
        }
    }

    private func fetchOrCreateUnclassifiedBook(modelContext: ModelContext) -> Book {
        let descriptor = FetchDescriptor<Book>(predicate: #Predicate { book in
            book.title == "분류되지 않음"
        })

        if let existingBook = try? modelContext.fetch(descriptor).first {
            return existingBook
        }

        let defaultBook = Book(title: "분류되지 않음")
        modelContext.insert(defaultBook)
        return defaultBook
    }

    private func nextPageSortOrder(in book: Book) -> Int {
        let currentMax = book.pages.compactMap(\.sortOrder).max() ?? 0
        return currentMax + 1
    }

}
