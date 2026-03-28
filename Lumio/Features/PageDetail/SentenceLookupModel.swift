import Foundation
import Observation
@preconcurrency import Translation

@Observable
@MainActor
final class SentenceLookupModel {
    let sentenceText: String
    let translationConfig: TranslationSession.Configuration?

    var translatedText = ""
    var translateError: String?
    var isTranslating = false
    var audioGuidanceAlert: AudioGuidanceAlert?

    init(sentence: SentenceItem) {
        sentenceText = sentence.text
        translationConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: "en-US"),
            target: Locale.Language(identifier: "ko-KR")
        )
    }

    func playAudio() {
        audioGuidanceAlert = SpeechService.shared.speakIfAvailable(text: sentenceText)
    }

    func beginTranslation() {
        isTranslating = true
    }

    func applyTranslation(_ text: String) {
        translatedText = text
        translateError = nil
        isTranslating = false
    }

    func handleTranslationFailure() {
        translatedText = ""
        translateError = "번역 결과를 가져오지 못했습니다."
        isTranslating = false
    }
}
