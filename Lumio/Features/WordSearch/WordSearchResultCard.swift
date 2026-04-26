import SwiftData
import SwiftUI
@preconcurrency import Translation

struct WordSearchResultCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var model: WordLookupModel
    @State private var editedMeaningDraft = ""
    @State private var showMeaningEditAlert = false

    init(word: String) {
        _model = State(initialValue: WordLookupModel(word: VocabularyItem(word: word)))
    }

    var body: some View {
        @Bindable var model = model

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
                } else if let translateError = model.translateError, model.currentMeaning.isEmpty {
                    Text(translateError)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if model.currentMeaning.isEmpty {
                    Text("뜻이 아직 없습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(model.currentMeaning)
                        .font(.body)
                }
            }

            actionButtons
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LumioColors.cardSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(LumioColors.cardStroke, lineWidth: 1)
        }
        .task {
            model.refreshSavedState(context: modelContext)
            model.loadPersistedMeaning(context: modelContext)
            model.recordRecentLookup(context: modelContext)
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
                    model.recordRecentLookup(context: modelContext)
                }
            } catch {
                await MainActor.run {
                    model.handleTranslationFailure()
                }
            }
        }
        .alert("뜻 수정", isPresented: $showMeaningEditAlert) {
            TextField("뜻", text: $editedMeaningDraft, axis: .vertical)
            Button("취소", role: .cancel) {}
            Button("저장") {
                model.applyEditedMeaning(editedMeaningDraft, context: modelContext)
                model.recordRecentLookup(context: modelContext)
            }
        } message: {
            Text("번역 결과가 어색하면 직접 수정해 저장할 수 있습니다.")
        }
        .alert("저장 실패", isPresented: $model.showSaveErrorAlert) {} message: {
            Text(model.saveErrorMessage ?? "단어 조회 데이터를 저장하지 못했습니다.")
        }
        .alert(item: $model.audioGuidanceAlert) { alert in
            Alert(
                title: Text("소리 확인"),
                message: Text(alert.message),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    model.playAudio()
                } label: {
                    Label("발음 듣기", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    model.toggleVocabularyBookmark(context: modelContext)
                } label: {
                    Label(
                        model.isSaved ? "저장됨" : "저장",
                        systemImage: model.isSaved ? "bookmark.fill" : "bookmark"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                Button {
                    openDictionary()
                } label: {
                    Label("웹 사전", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    editedMeaningDraft = model.currentMeaning
                    showMeaningEditAlert = true
                } label: {
                    Label("뜻 수정", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .labelStyle(.titleAndIcon)
    }

    private func openDictionary() {
        guard let url = WordLookupStore.dictionaryURL(for: model.word.word) else { return }
        openURL(url)
    }

    nonisolated private func translateWord(
        session: sending TranslationSession,
        text: String
    ) async throws -> String {
        try await session.prepareTranslation()
        return try await session.translate(text).targetText
    }
}
