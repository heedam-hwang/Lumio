import SwiftData
import SwiftUI

private struct PageDetailContentList: View {
    let page: Page
    let sortedSentences: [SentenceItem]
    let savedWordSet: Set<String>
    let isEditing: Bool
    let selectedSentenceID: UUID?
    let selectedWordText: String?
    let onToggleEditing: () -> Void
    let onShowImage: () -> Void
    let onRenamePage: () -> Void
    let onOpenSentence: (SentenceItem) -> Void
    let onEditSentence: (SentenceItem) -> Void
    let onOpenWord: (String) -> Void
    let onDeleteSentence: (SentenceItem) -> Void
    let onMoveSentences: (IndexSet, Int) -> Void
    private let canvasColor = LumioColors.canvasWarm

    var body: some View {
        List {
            Section {
                PageHeaderView(
                    page: page,
                    isEditing: isEditing,
                    onImageTap: onShowImage,
                    onRenameTap: onRenamePage
                )
                .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 12, trailing: 20))
                .listRowSeparator(.hidden)
            }

            SentenceListSectionView(
                sentences: sortedSentences,
                pageIsTextAnalyzed: page.isTextAnalyzed,
                selectedSentenceID: selectedSentenceID,
                isEditing: isEditing,
                selectedWordText: selectedWordText,
                savedWords: savedWordSet,
                onSentenceTap: onOpenSentence,
                onEditTap: onEditSentence,
                onWordTap: onOpenWord,
                onDeleteTap: onDeleteSentence,
                onMove: isEditing ? onMoveSentences : nil
            )
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(canvasColor)
        .navigationTitle("페이지")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "완료" : "편집", action: onToggleEditing)
            }
        }
    }
}

struct PageDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\SavedVocabulary.word)]) private var savedWords: [SavedVocabulary]

    let page: Page

    @State private var editMode: EditMode = .inactive
    @State private var selectedSentenceID: UUID?
    @State private var selectedWordText: String?
    @State private var selectedSentenceForSheet: SentenceItem?
    @State private var selectedWordForSheet: VocabularyItem?
    @State private var isAnalyzing = false
    @State private var analyzeErrorMessage: String?
    @State private var showAnalyzeErrorAlert = false
    @State private var showImagePreview = false
    @State private var pageTitleDraft = ""
    @State private var showPageRenameAlert = false
    @State private var editingDraft: SentenceEditingDraft?
    @State private var pendingSentenceDeletion: SentenceItem?
    @State private var showSentenceDeleteConfirmation = false
    @State private var saveErrorMessage: String?
    @State private var showSaveErrorAlert = false

    private var sortedSentences: [SentenceItem] {
        page.sentences.sorted { $0.order < $1.order }
    }

    private var savedWordSet: Set<String> {
        Set(savedWords.map { $0.word.lowercased() })
    }

    private var isEditing: Bool {
        editMode == .active
    }

    var body: some View {
        PageDetailContentList(
            page: page,
            sortedSentences: sortedSentences,
            savedWordSet: savedWordSet,
            isEditing: isEditing,
            selectedSentenceID: selectedSentenceID,
            selectedWordText: selectedWordText,
            onToggleEditing: toggleEditing,
            onShowImage: { showImagePreview = true },
            onRenamePage: beginPageRename,
            onOpenSentence: openSentence,
            onEditSentence: beginSentenceEditing,
            onOpenWord: openWord,
            onDeleteSentence: confirmSentenceDelete,
            onMoveSentences: moveSentences
        )
        .environment(\.editMode, $editMode)
        .overlay {
            if isAnalyzing {
                LoadingOverlayView(title: "문장/단어 감지 중")
            }
        }
        .task(id: page.persistentModelID) {
            await ensureDetectionDataIfNeeded()
        }
        .alert("OCR 처리 실패", isPresented: $showAnalyzeErrorAlert) {} message: {
            Text(analyzeErrorMessage ?? "문장/단어 감지에 실패했습니다.")
        }
        .sheet(item: $selectedSentenceForSheet, content: SentenceLookupSheet.init)
        .sheet(item: $selectedWordForSheet, content: WordLookupSheet.init)
        .sheet(item: $editingDraft) { draft in
            SentenceEditSheet(
                draft: draft,
                onCancel: { editingDraft = nil },
                onSave: { text in
                    saveEditedSentence(draft: draft, text: text)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            PageImagePreviewView(imageData: page.imageData) {
                showImagePreview = false
            }
        }
        .alert("페이지 제목 변경", isPresented: $showPageRenameAlert) {
            TextField("페이지 제목", text: $pageTitleDraft)
            Button("취소", role: .cancel) {}
            Button("저장", action: saveEditedPageTitle)
        } message: {
            Text("페이지 이름을 수정할 수 있습니다.")
        }
        .confirmationDialog("문장을 삭제할까요?", isPresented: $showSentenceDeleteConfirmation, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                if let pendingSentenceDeletion {
                    deleteSentence(pendingSentenceDeletion)
                }
                pendingSentenceDeletion = nil
            }
            Button("취소", role: .cancel) {
                pendingSentenceDeletion = nil
            }
        } message: {
            Text("삭제한 문장은 복구할 수 없으며, 문장 번호는 자동으로 다시 정렬됩니다.")
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert) {} message: {
            Text(saveErrorMessage ?? "데이터 저장에 실패했습니다.")
        }
    }

    @MainActor
    private func ensureDetectionDataIfNeeded() async {
        guard !page.isTextAnalyzed else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            try await PageTextAnalyzer.analyzeIfNeeded(page: page, context: modelContext)
        } catch {
            analyzeErrorMessage = error.localizedDescription
            showAnalyzeErrorAlert = true
        }
    }

    private func beginPageRename() {
        pageTitleDraft = page.title ?? ""
        showPageRenameAlert = true
    }

    private func toggleEditing() {
        withAnimation {
            editMode = isEditing ? .inactive : .active
        }
    }

    private func saveEditedPageTitle() {
        let trimmed = pageTitleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        page.title = trimmed.isEmpty ? nil : trimmed

        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = "페이지 제목 저장에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    private func openSentence(_ sentence: SentenceItem) {
        guard !isEditing else { return }
        selectedSentenceID = sentence.id
        selectedSentenceForSheet = sentence
    }

    private func beginSentenceEditing(_ sentence: SentenceItem) {
        editingDraft = SentenceEditingDraft(sentence: sentence)
    }

    private func openWord(_ tappedWord: String) {
        selectedWordText = tappedWord
        selectedWordForSheet = VocabularyItem(word: tappedWord)
    }

    private func confirmSentenceDelete(_ sentence: SentenceItem) {
        pendingSentenceDeletion = sentence
        showSentenceDeleteConfirmation = true
    }

    private func saveEditedSentence(draft: SentenceEditingDraft, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let editingSentence = sortedSentences.first(where: { $0.id == draft.id }) else {
            editingDraft = nil
            return
        }

        if trimmed.isEmpty {
            editingDraft = nil
            deleteSentence(editingSentence)
            return
        }

        editingSentence.text = trimmed

        do {
            try modelContext.save()
            editingDraft = nil
        } catch {
            saveErrorMessage = "문장 수정에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    private func deleteSentence(_ sentence: SentenceItem) {
        let remainingSentences = sortedSentences.filter { $0.id != sentence.id }
        applySentenceOrder(remainingSentences)

        modelContext.delete(sentence)

        do {
            try modelContext.save()

            if selectedSentenceID == sentence.id {
                selectedSentenceID = nil
            }
            if selectedSentenceForSheet?.id == sentence.id {
                selectedSentenceForSheet = nil
            }
            if editingDraft?.id == sentence.id {
                editingDraft = nil
            }
            pendingSentenceDeletion = nil
        } catch {
            saveErrorMessage = "문장 삭제에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    private func applySentenceOrder(_ sentences: [SentenceItem]) {
        page.sentences = sentences
        for (index, item) in sentences.enumerated() {
            item.order = index + 1
        }
    }

    private func moveSentences(from source: IndexSet, to destination: Int) {
        var reordered = sortedSentences
        reordered.move(fromOffsets: source, toOffset: destination)
        applySentenceOrder(reordered)

        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = "문장 순서 저장에 실패했습니다."
            showSaveErrorAlert = true
        }
    }
}
