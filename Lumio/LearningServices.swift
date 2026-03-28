import AVFAudio
import Foundation
import SwiftData
import SwiftUI
import Translation

struct AudioGuidanceAlert: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
final class SpeechService {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(text: String, language: String = "en-US") {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }

    func audioGuidanceMessage() -> String? {
        let session = AVAudioSession.sharedInstance()
        let isVolumeOff = session.outputVolume <= 0.001
        let isMuted: Bool

        if #available(iOS 26.0, *) {
            isMuted = session.isOutputMuted
        } else {
            isMuted = false
        }

        guard isMuted || isVolumeOff else { return nil }
        return "소리가 꺼져 있습니다. 무음 모드나 볼륨 설정을 확인해 주세요."
    }

    func speakIfAvailable(text: String, language: String = "en-US") -> AudioGuidanceAlert? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        if let message = audioGuidanceMessage() {
            return AudioGuidanceAlert(message: message)
        }

        speak(text: text, language: language)
        return nil
    }
}

struct SentenceLookupSheet: View {
    let sentence: SentenceItem

    @Environment(\.dismiss) private var dismiss

    @State private var translatedText = ""
    @State private var translateError: String?
    @State private var isTranslating = false
    @State private var translationConfig: TranslationSession.Configuration?
    @State private var audioGuidanceAlert: AudioGuidanceAlert?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(sentence.text)
                    .font(.body)

                Divider()

                Group {
                    if isTranslating {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("번역 중")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if let translateError {
                        Text(translateError)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(translatedText)
                            .font(.body)
                    }
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
                    Button("듣기") {
                        audioGuidanceAlert = SpeechService.shared.speakIfAvailable(text: sentence.text)
                    }
                }
            }
        }
        .onAppear {
            translationConfig = TranslationSession.Configuration(
                source: Locale.Language(identifier: "en-US"),
                target: Locale.Language(identifier: "ko-KR")
            )
        }
        .translationTask(translationConfig) { session in
            await translateSentence(session: session)
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
    private func translateSentence(session: TranslationSession) async {
        isTranslating = true
        defer { isTranslating = false }

        do {
            try await session.prepareTranslation()
            let response = try await session.translate(sentence.text)
            translatedText = response.targetText
            translateError = nil
        } catch {
            translatedText = ""
            translateError = "번역 결과를 가져오지 못했습니다."
        }
    }
}

struct WordLookupSheet: View {
    let word: VocabularyItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var translatedMeaning = ""
    @State private var translateError: String?
    @State private var isTranslating = false
    @State private var translationConfig: TranslationSession.Configuration?
    @State private var saveErrorMessage: String?
    @State private var showSaveErrorAlert = false
    @State private var isSaved = false
    @State private var audioGuidanceAlert: AudioGuidanceAlert?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(word.word)
                    .font(.title3.weight(.semibold))

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("뜻")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isTranslating {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("조회 중")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if let translateError {
                        Text(translateError)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(translatedMeaning)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("듣기") {
                        audioGuidanceAlert = SpeechService.shared.speakIfAvailable(text: word.word)
                    }

                    Button {
                        toggleVocabularyBookmark()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    }
                    .accessibilityLabel("단어장 저장")
                }
            }
        }
        .onAppear {
            refreshSavedState()
            translationConfig = TranslationSession.Configuration(
                source: Locale.Language(identifier: "en-US"),
                target: Locale.Language(identifier: "ko-KR")
            )
        }
        .translationTask(translationConfig) { session in
            await translateWord(session: session)
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert, actions: {
            Button("확인", role: .cancel) {}
        }, message: {
            Text(saveErrorMessage ?? "단어장 저장에 실패했습니다.")
        })
        .alert(item: $audioGuidanceAlert) { alert in
            Alert(
                title: Text("소리 확인"),
                message: Text(alert.message),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    @MainActor
    private func translateWord(session: TranslationSession) async {
        isTranslating = true
        defer { isTranslating = false }

        do {
            try await session.prepareTranslation()
            let response = try await session.translate(word.word)
            translatedMeaning = response.targetText
            translateError = nil
            word.meaning = response.targetText
        } catch {
            translateError = "단어 뜻을 가져오지 못했습니다."
        }
    }

    @MainActor
    private func refreshSavedState() {
        isSaved = (try? existingSavedItem()) != nil
    }

    @MainActor
    private func toggleVocabularyBookmark() {
        do {
            if let existing = try existingSavedItem() {
                modelContext.delete(existing)
                try modelContext.save()
                isSaved = false
                return
            }

            try saveToVocabularyBook()
            isSaved = true
        } catch {
            saveErrorMessage = "단어장 저장 상태 변경에 실패했습니다. 다시 시도해 주세요."
            showSaveErrorAlert = true
        }
    }

    @MainActor
    private func saveToVocabularyBook() throws {
        let currentWord = word.word.lowercased()
        if let existing = try existingSavedItem() {
            existing.meaning = word.meaning
            try modelContext.save()
            return
        }

        let item = SavedVocabulary(
            word: currentWord,
            meaning: word.meaning
        )
        modelContext.insert(item)
        try modelContext.save()
    }

    @MainActor
    private func existingSavedItem() throws -> SavedVocabulary? {
        let normalized = word.word.lowercased()
        let descriptor = FetchDescriptor<SavedVocabulary>()
        return try modelContext.fetch(descriptor).first(where: { item in
            item.word.lowercased() == normalized
        })
    }
}
