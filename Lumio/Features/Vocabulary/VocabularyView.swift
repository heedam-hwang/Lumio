import SwiftData
import SwiftUI

struct VocabularyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\SavedVocabulary.createdAt, order: .reverse)]) private var savedWords: [SavedVocabulary]

    @State private var unbookmarkingWordIDs = Set<UUID>()
    @State private var audioGuidanceAlert: AudioGuidanceAlert?

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
                            .padding(.leading, 6)

                            Spacer(minLength: 0)

                            Button {
                                unbookmark(item)
                            } label: {
                                Label(
                                    "\(item.word) 북마크 해제",
                                    systemImage: unbookmarkingWordIDs.contains(item.id) ? "bookmark" : "bookmark.fill"
                                )
                                .labelStyle(.iconOnly)
                                .frame(width: 44, height: 44)
                            }
                            .disabled(unbookmarkingWordIDs.contains(item.id))
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
        .alert(item: $audioGuidanceAlert) { alert in
            Alert(
                title: Text("소리 확인"),
                message: Text(alert.message),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    @MainActor
    private func unbookmark(_ item: SavedVocabulary) {
        unbookmarkingWordIDs.insert(item.id)

        Task {
            try? await Task.sleep(for: .milliseconds(180))
            remove(item)
            unbookmarkingWordIDs.remove(item.id)
        }
    }

    @MainActor
    private func remove(_ item: SavedVocabulary) {
        modelContext.delete(item)
        try? modelContext.save()
    }
}
