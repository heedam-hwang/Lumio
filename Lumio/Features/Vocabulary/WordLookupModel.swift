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
    var machineTranslatedMeaning: String?
    var editedMeaning: String?
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
        machineTranslatedMeaning = text
        translatedMeaning = editedMeaning ?? text
        translateError = nil
        word.meaning = translatedMeaning
        isTranslating = false
    }

    func handleTranslationFailure() {
        translateError = "단어 뜻을 가져오지 못했습니다."
        isTranslating = false
    }

    func refreshSavedState(context: ModelContext) {
        isSaved = (try? WordLookupStore.fetchSavedVocabulary(word: word.word, context: context)) != nil
    }

    func loadPersistedMeaning(context: ModelContext) {
        let savedItem = try? WordLookupStore.fetchSavedVocabulary(word: word.word, context: context)
        let recentLookup = try? WordLookupStore.fetchRecentLookup(word: word.word, context: context)

        let overrideMeaning = recentLookup?.editedMeaning ?? savedItem?.meaning
        guard let overrideMeaning, !overrideMeaning.isEmpty else { return }

        editedMeaning = overrideMeaning
        translatedMeaning = overrideMeaning
        word.meaning = overrideMeaning
        if let pronunciation = recentLookup?.pronunciation {
            word.pronunciation = pronunciation
        }
    }

    func recordRecentLookup(context: ModelContext) {
        let displayedMeaning = currentMeaning
        guard !displayedMeaning.isEmpty || !(word.pronunciation ?? "").isEmpty else { return }

        do {
            _ = try WordLookupStore.upsertRecentLookup(
                word: word.word,
                meaning: displayedMeaning,
                pronunciation: word.pronunciation,
                editedMeaning: editedMeaning,
                context: context
            )
        } catch {
            saveErrorMessage = "최근 조회 저장에 실패했습니다. 다시 시도해 주세요."
            showSaveErrorAlert = true
        }
    }

    func applyEditedMeaning(_ meaning: String, context: ModelContext) {
        let trimmed = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        editedMeaning = trimmed
        translatedMeaning = trimmed
        word.meaning = trimmed
        translateError = nil

        do {
            try WordLookupStore.updateMeaningOverride(
                word: word.word,
                meaning: trimmed,
                pronunciation: word.pronunciation,
                context: context
            )
            refreshSavedState(context: context)
        } catch {
            saveErrorMessage = "뜻 수정 저장에 실패했습니다. 다시 시도해 주세요."
            showSaveErrorAlert = true
        }
    }

    func toggleVocabularyBookmark(context: ModelContext) {
        do {
            if let existing = try WordLookupStore.fetchSavedVocabulary(word: word.word, context: context) {
                context.delete(existing)
                try context.save()
                isSaved = false
                return
            }

            _ = try WordLookupStore.upsertSavedVocabulary(
                word: word.word,
                meaning: currentMeaning,
                pronunciation: word.pronunciation,
                context: context
            )
            isSaved = true
        } catch {
            saveErrorMessage = "단어장 저장 상태 변경에 실패했습니다. 다시 시도해 주세요."
            showSaveErrorAlert = true
        }
    }

    var currentMeaning: String {
        translatedMeaning.isEmpty ? (word.meaning ?? "") : translatedMeaning
    }
}
