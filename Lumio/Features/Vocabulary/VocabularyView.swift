import SwiftData
import SwiftUI

struct VocabularyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [SortDescriptor(\SavedVocabulary.createdAt, order: .reverse)]) private var savedWords: [SavedVocabulary]

    @State private var pendingRemovalWordIDs = Set<UUID>()
    @State private var audioGuidanceAlert: AudioGuidanceAlert?
    @State private var saveErrorMessage: String?
    @State private var showSaveErrorAlert = false
    @State private var editingWord: SavedVocabulary?
    @State private var meaningDraft = ""

    var body: some View {
        Group {
            if savedWords.isEmpty {
                ContentUnavailableView {
                    Label("단어장이 비어 있습니다", systemImage: "text.book.closed")
                } description: {
                    Text("단어 조회 화면에서 북마크를 눌러 단어를 저장해 보세요.")
                }
            } else {
                List(savedWords) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.word)
                                .font(.headline)

                            Button {
                                audioGuidanceAlert = SpeechService.shared.speakIfAvailable(text: item.word)
                            } label: {
                                Label("\(item.word) 발음 듣기", systemImage: "speaker.wave.2.fill")
                                    .labelStyle(.iconOnly)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderless)
                            .padding(.leading, 6)

                            Spacer(minLength: 0)

                            Button {
                                toggleBookmarkState(for: item)
                            } label: {
                                Label(
                                    "\(item.word) 북마크 해제",
                                    systemImage: pendingRemovalWordIDs.contains(item.id) ? "bookmark" : "bookmark.fill"
                                )
                                .labelStyle(.iconOnly)
                                .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderless)

                            Button {
                                beginMeaningEdit(for: item)
                            } label: {
                                Label("\(item.word) 뜻 수정", systemImage: "pencil")
                                    .labelStyle(.iconOnly)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderless)
                        }

                        if let meaning = item.meaning, !meaning.isEmpty {
                            Text(meaning)
                                .font(.body)
                        }

                        Text(item.createdAt.formatted(date: .numeric, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("단어장")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear(perform: flushPendingRemovals)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase != .active else { return }
            flushPendingRemovals()
        }
        .meaningEditAlert(
            isPresented: Binding(
                get: { editingWord != nil },
                set: { isPresented in
                    if !isPresented {
                        editingWord = nil
                    }
                }
            ),
            draft: $meaningDraft
        ) {
            saveMeaningEdit()
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert) {} message: {
            Text(saveErrorMessage ?? "단어장 저장 상태 반영에 실패했습니다.")
        }
        .alert(item: $audioGuidanceAlert) { alert in
            Alert(
                title: Text("소리 확인"),
                message: Text(alert.message),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    @MainActor
    private func toggleBookmarkState(for item: SavedVocabulary) {
        if pendingRemovalWordIDs.contains(item.id) {
            pendingRemovalWordIDs.remove(item.id)
        } else {
            pendingRemovalWordIDs.insert(item.id)
        }
    }

    @MainActor
    private func flushPendingRemovals() {
        guard !pendingRemovalWordIDs.isEmpty else { return }

        let pendingItems = savedWords.filter { pendingRemovalWordIDs.contains($0.id) }
        guard !pendingItems.isEmpty else {
            pendingRemovalWordIDs.removeAll()
            return
        }

        for item in pendingItems {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
            pendingRemovalWordIDs.removeAll()
        } catch {
            saveErrorMessage = "단어장 변경사항 저장에 실패했습니다."
            showSaveErrorAlert = true
        }
    }

    @MainActor
    private func beginMeaningEdit(for item: SavedVocabulary) {
        editingWord = item
        meaningDraft = item.meaning ?? ""
    }

    @MainActor
    private func saveMeaningEdit() {
        guard let editingWord else { return }

        do {
            try WordLookupStore.updateMeaningOverride(
                word: editingWord.word,
                meaning: meaningDraft,
                pronunciation: editingWord.pronunciation,
                context: modelContext
            )
            self.editingWord = nil
        } catch {
            saveErrorMessage = "뜻 수정 저장에 실패했습니다."
            showSaveErrorAlert = true
        }
    }
}
