import Foundation
import Observation
import SwiftData
@preconcurrency import Translation

@Observable
@MainActor
final class WordLookupModel {
    let word: VocabularyItem
    let translationConfig: TranslationSession.Configuration?

    var translatedMeaning = ""
    var translateError: String?
    var isTranslating = false
    var saveErrorMessage: String?
    var showSaveErrorAlert = false
    var isSaved = false
    var audioGuidanceAlert: AudioGuidanceAlert?

    init(word: VocabularyItem) {
        self.word = word
        translationConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: "en-US"),
            target: Locale.Language(identifier: "ko-KR")
        )
    }

    func playAudio() {
        audioGuidanceAlert = SpeechService.shared.speakIfAvailable(text: word.word)
    }

    func beginTranslation() {
        isTranslating = true
    }

    func applyTranslation(_ text: String) {
        translatedMeaning = text
        translateError = nil
        word.meaning = text
        isTranslating = false
    }

    func handleTranslationFailure() {
        translateError = "단어 뜻을 가져오지 못했습니다."
        isTranslating = false
    }

    func refreshSavedState(context: ModelContext) {
        isSaved = (try? existingSavedItem(context: context)) != nil
    }

    func toggleVocabularyBookmark(context: ModelContext) {
        do {
            if let existing = try existingSavedItem(context: context) {
                context.delete(existing)
                try context.save()
                isSaved = false
                return
            }

            try saveToVocabularyBook(context: context)
            isSaved = true
        } catch {
            saveErrorMessage = "단어장 저장 상태 변경에 실패했습니다. 다시 시도해 주세요."
            showSaveErrorAlert = true
        }
    }

    private func saveToVocabularyBook(context: ModelContext) throws {
        let currentWord = word.word.lowercased()
        if let existing = try existingSavedItem(context: context) {
            existing.meaning = word.meaning
            try context.save()
            return
        }

        let item = SavedVocabulary(word: currentWord, meaning: word.meaning)
        context.insert(item)
        try context.save()
    }

    private func existingSavedItem(context: ModelContext) throws -> SavedVocabulary? {
        let normalized = word.word.lowercased()
        let descriptor = FetchDescriptor<SavedVocabulary>()
        return try context.fetch(descriptor).first(where: { item in
            item.word.lowercased() == normalized
        })
    }
}
