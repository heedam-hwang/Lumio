import SwiftData
import SwiftUI
@preconcurrency import Translation

struct WordLookupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var model: WordLookupModel

    init(word: VocabularyItem) {
        _model = State(initialValue: WordLookupModel(word: word))
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(model.word.word)
                    .font(.title3.bold())

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("뜻")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if model.isTranslating {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("조회 중")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if let translateError = model.translateError {
                        Text(translateError)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(model.translatedMeaning)
                            .font(.body)
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("단어 보기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        model.playAudio()
                    } label: {
                        Label("듣기", systemImage: "speaker.wave.2.fill")
                    }

                    Button {
                        model.toggleVocabularyBookmark(context: modelContext)
                    } label: {
                        Label("단어장 저장", systemImage: model.isSaved ? "bookmark.fill" : "bookmark")
                    }
                }
            }
        }
        .task {
            model.refreshSavedState(context: modelContext)
        }
        .translationTask(model.translationConfig) { session in
            let word = await MainActor.run {
                model.beginTranslation()
                return model.word.word
            }

            do {
                let translatedText = try await translateWord(session: session, text: word)
                await MainActor.run {
                    model.applyTranslation(translatedText)
                }
            } catch {
                await MainActor.run {
                    model.handleTranslationFailure()
                }
            }
        }
        .alert("저장 실패", isPresented: $model.showSaveErrorAlert) {} message: {
            Text(model.saveErrorMessage ?? "단어장 저장에 실패했습니다.")
        }
        .alert(item: $model.audioGuidanceAlert) { alert in
            Alert(
                title: Text("소리 확인"),
                message: Text(alert.message),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    nonisolated private func translateWord(
        session: sending TranslationSession,
        text: String
    ) async throws -> String {
        try await session.prepareTranslation()
        return try await session.translate(text).targetText
    }
}
