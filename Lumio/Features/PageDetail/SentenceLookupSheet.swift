import SwiftUI
@preconcurrency import Translation

struct SentenceLookupSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: SentenceLookupModel

    init(sentence: SentenceItem) {
        _model = State(initialValue: SentenceLookupModel(sentence: sentence))
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(model.sentenceText)
                    .font(.body)

                Divider()

                if model.isTranslating {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("번역 중")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let translateError = model.translateError {
                    Text(translateError)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(model.translatedText)
                        .font(.body)
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("문장 보기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        model.playAudio()
                    } label: {
                        Label("듣기", systemImage: "speaker.wave.2.fill")
                    }
                }
            }
        }
        .translationTask(model.translationConfig) { session in
            let text = await MainActor.run {
                model.beginTranslation()
                return model.sentenceText
            }

            do {
                let translatedText = try await translateSentence(session: session, text: text)
                await MainActor.run {
                    model.applyTranslation(translatedText)
                }
            } catch {
                await MainActor.run {
                    model.handleTranslationFailure()
                }
            }
        }
        .alert(item: $model.audioGuidanceAlert) { alert in
            Alert(
                title: Text("소리 확인"),
                message: Text(alert.message),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    nonisolated private func translateSentence(
        session: sending TranslationSession,
        text: String
    ) async throws -> String {
        try await session.prepareTranslation()
        return try await session.translate(text).targetText
    }
}
