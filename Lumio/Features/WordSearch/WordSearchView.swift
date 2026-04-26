import SwiftData
import SwiftUI

struct WordSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\RecentWordLookup.lastViewedAt, order: .reverse)]) private var recentLookups: [RecentWordLookup]
    @Query(sort: [SortDescriptor(\SavedVocabulary.word)]) private var savedWords: [SavedVocabulary]

    @State private var searchText = ""
    @State private var activeLookupWord: String?
    @State private var activeLookupID = UUID()
    @State private var saveErrorMessage: String?
    @State private var showSaveErrorAlert = false
    @State private var showClearConfirmation = false
    @State private var editingRecentWord: String?
    @State private var recentMeaningDraft = ""
    @State private var pendingRecentDeletionWord: String?
    @FocusState private var isSearchFieldFocused: Bool

    private var savedWordSet: Set<String> {
        Set(savedWords.map { WordLookupStore.normalizedWord($0.word) })
    }

    var body: some View {
        List {
            searchSection
            currentResultSection
            recentLookupSection
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("단어 검색")
        .navigationBarTitleDisplayMode(.inline)
        .simultaneousGesture(
            TapGesture().onEnded {
                isSearchFieldFocused = false
            }
        )
        .alert("최근 조회를 삭제할까요?", isPresented: $showClearConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive, action: clearRecentLookups)
        } message: {
            Text("최근 조회한 단어 내역이 모두 삭제됩니다.")
        }
        .alert(
            "이 최근 조회를 삭제할까요?",
            isPresented: Binding(
                get: { pendingRecentDeletionWord != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingRecentDeletionWord = nil
                    }
                }
            )
        ) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive, action: confirmRecentDeletion)
        } message: {
            Text("선택한 최근 조회 항목이 삭제됩니다.")
        }
        .meaningEditAlert(
            isPresented: Binding(
                get: { editingRecentWord != nil },
                set: { isPresented in
                    if !isPresented {
                        editingRecentWord = nil
                    }
                }
            ),
            draft: $recentMeaningDraft
        ) {
            saveRecentMeaningEdit()
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert) {} message: {
            Text(saveErrorMessage ?? "최근 조회를 업데이트하지 못했습니다.")
        }
    }

    private var searchSection: some View {
        Section {
            HStack(spacing: 12) {
                TextField("영어 단어 입력", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isSearchFieldFocused)
                    .onSubmit(performSearch)

                Button("검색", action: performSearch)
                    .buttonStyle(.borderedProminent)
            }
        } header: {
            Text("단어 검색")
        }
    }

    private var currentResultSection: some View {
        Section("현재 조회 결과") {
            if let activeLookupWord {
                WordSearchResultCard(word: activeLookupWord)
                    .id(activeLookupID)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
            } else {
                ContentUnavailableView(
                    "조회할 단어를 입력해 주세요",
                    systemImage: "text.magnifyingglass"
                )
            }
        }
    }

    private var recentLookupSection: some View {
        Section {
            if recentLookups.isEmpty {
                ContentUnavailableView(
                    "최근 조회가 없습니다",
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    description: Text("최근 조회한 단어 30개가 여기에 유지됩니다.")
                )
            } else {
                ForEach(Array(recentLookups), id: \.id) { item in
                    recentLookupRow(item)
                }
            }
        } header: {
            HStack {
                Text("최근 조회")
                Spacer()
                if !recentLookups.isEmpty {
                    Button("전체 삭제") {
                        isSearchFieldFocused = false
                        showClearConfirmation = true
                    }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func recentLookupRow(_ item: RecentWordLookup) -> some View {
        let normalizedWord = WordLookupStore.normalizedWord(item.word)
        let isSaved = savedWordSet.contains(normalizedWord)

        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.word)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let meaning = item.editedMeaning ?? item.meaning, !meaning.isEmpty {
                    Text(meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Text(item.lastViewedAt.formatted(date: .numeric, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 2) {
                Button {
                    beginRecentMeaningEdit(item)
                } label: {
                    Label("\(item.word) 뜻 수정", systemImage: "pencil")
                        .labelStyle(.iconOnly)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderless)

                Button {
                    toggleRecentSave(item)
                } label: {
                    Label(
                        isSaved ? "저장됨" : "저장",
                        systemImage: isSaved ? "bookmark.fill" : "bookmark"
                    )
                    .labelStyle(.iconOnly)
                    .frame(width: 36, height: 36)
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    beginRecentDeletion(item)
                } label: {
                    Label("\(item.word) 삭제", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearchFieldFocused = false
        searchText = trimmed
        activeLookupWord = trimmed
        activeLookupID = UUID()
    }

    private func clearRecentLookups() {
        isSearchFieldFocused = false
        do {
            try WordLookupStore.clearRecentLookups(context: modelContext)
        } catch {
            saveErrorMessage = "최근 조회 삭제에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    private func toggleRecentSave(_ item: RecentWordLookup) {
        isSearchFieldFocused = false

        do {
            if let existing = try WordLookupStore.fetchSavedVocabulary(word: item.word, context: modelContext) {
                modelContext.delete(existing)
                try modelContext.save()
                return
            }

            _ = try WordLookupStore.upsertSavedVocabulary(
                word: item.word,
                meaning: item.editedMeaning ?? item.meaning,
                pronunciation: item.pronunciation,
                context: modelContext
            )
        } catch {
            saveErrorMessage = "단어장 저장 상태 변경에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    private func beginRecentMeaningEdit(_ item: RecentWordLookup) {
        isSearchFieldFocused = false
        editingRecentWord = item.word
        recentMeaningDraft = item.editedMeaning ?? item.meaning ?? ""
    }

    private func saveRecentMeaningEdit() {
        guard let editingRecentWord else { return }

        do {
            try WordLookupStore.updateMeaningOverride(
                word: editingRecentWord,
                meaning: recentMeaningDraft,
                context: modelContext
            )
            if activeLookupWord == editingRecentWord {
                activeLookupID = UUID()
            }
            self.editingRecentWord = nil
        } catch {
            saveErrorMessage = "뜻 수정 저장에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    private func beginRecentDeletion(_ item: RecentWordLookup) {
        isSearchFieldFocused = false
        pendingRecentDeletionWord = item.word
    }

    private func confirmRecentDeletion() {
        guard let pendingRecentDeletionWord else { return }
        isSearchFieldFocused = false

        do {
            try WordLookupStore.deleteRecentLookup(word: pendingRecentDeletionWord, context: modelContext)
            if activeLookupWord == pendingRecentDeletionWord {
                activeLookupWord = nil
                activeLookupID = UUID()
            }
            self.pendingRecentDeletionWord = nil
        } catch {
            saveErrorMessage = "최근 조회 삭제에 실패했습니다."
            showSaveErrorAlert = true
        }
    }
}
