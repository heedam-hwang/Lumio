import Foundation
import SwiftData

@MainActor
enum WordLookupStore {
    static let recentLimit = 30

    static func normalizedWord(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func dictionaryURL(for word: String) -> URL? {
        let query = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }

        var components = URLComponents(string: "https://dict.naver.com/search.dict")
        components?.queryItems = [URLQueryItem(name: "query", value: query)]
        return components?.url
    }

    static func fetchSavedVocabulary(
        word: String,
        context: ModelContext
    ) throws -> SavedVocabulary? {
        let normalized = normalizedWord(word)
        let descriptor = FetchDescriptor<SavedVocabulary>()
        return try context.fetch(descriptor).first {
            normalizedWord($0.word) == normalized
        }
    }

    static func fetchRecentLookup(
        word: String,
        context: ModelContext
    ) throws -> RecentWordLookup? {
        let normalized = normalizedWord(word)
        let descriptor = FetchDescriptor<RecentWordLookup>()
        return try context.fetch(descriptor).first {
            normalizedWord($0.word) == normalized
        }
    }

    static func upsertSavedVocabulary(
        word: String,
        meaning: String?,
        pronunciation: String? = nil,
        context: ModelContext
    ) throws -> SavedVocabulary {
        let normalized = normalizedWord(word)

        if let existing = try fetchSavedVocabulary(word: normalized, context: context) {
            existing.word = normalized
            existing.meaning = normalizedMeaning(meaning)
            existing.pronunciation = pronunciation
            try context.save()
            return existing
        }

        let item = SavedVocabulary(
            word: normalized,
            meaning: normalizedMeaning(meaning),
            pronunciation: pronunciation
        )
        context.insert(item)
        try context.save()
        return item
    }

    static func upsertRecentLookup(
        word: String,
        meaning: String?,
        pronunciation: String? = nil,
        editedMeaning: String? = nil,
        viewedAt: Date = .now,
        context: ModelContext
    ) throws -> RecentWordLookup {
        let normalized = normalizedWord(word)

        let item: RecentWordLookup
        if let existing = try fetchRecentLookup(word: normalized, context: context) {
            item = existing
        } else {
            item = RecentWordLookup(word: normalized)
            context.insert(item)
        }

        item.word = normalized
        item.meaning = normalizedMeaning(meaning)
        item.pronunciation = pronunciation
        item.editedMeaning = normalizedMeaning(editedMeaning)
        item.lastViewedAt = viewedAt

        try trimRecentLookupsIfNeeded(context: context, keeping: item.id)
        try context.save()
        return item
    }

    static func updateMeaningOverride(
        word: String,
        meaning: String,
        pronunciation: String? = nil,
        context: ModelContext
    ) throws {
        let normalized = normalizedWord(word)
        let cleanedMeaning = normalizedMeaning(meaning)

        guard let cleanedMeaning else { return }

        if let existingRecent = try fetchRecentLookup(word: normalized, context: context) {
            existingRecent.word = normalized
            existingRecent.meaning = cleanedMeaning
            existingRecent.editedMeaning = cleanedMeaning
            existingRecent.pronunciation = pronunciation
            existingRecent.lastViewedAt = .now
        } else {
            context.insert(
                RecentWordLookup(
                    word: normalized,
                    meaning: cleanedMeaning,
                    pronunciation: pronunciation,
                    editedMeaning: cleanedMeaning
                )
            )
        }

        if let existingSaved = try fetchSavedVocabulary(word: normalized, context: context) {
            existingSaved.word = normalized
            existingSaved.meaning = cleanedMeaning
            existingSaved.pronunciation = pronunciation
        }

        try trimRecentLookupsIfNeeded(context: context)
        try context.save()
    }

    static func clearRecentLookups(context: ModelContext) throws {
        let descriptor = FetchDescriptor<RecentWordLookup>()
        let items = try context.fetch(descriptor)
        for item in items {
            context.delete(item)
        }
        try context.save()
    }

    private static func trimRecentLookupsIfNeeded(
        context: ModelContext,
        keeping keptID: UUID? = nil
    ) throws {
        let descriptor = FetchDescriptor<RecentWordLookup>(
            sortBy: [SortDescriptor(\.lastViewedAt, order: .reverse)]
        )
        let items = try context.fetch(descriptor)
        guard items.count > recentLimit else { return }

        for item in items.dropFirst(recentLimit) where item.id != keptID {
            context.delete(item)
        }
    }

    private static func normalizedMeaning(_ meaning: String?) -> String? {
        guard let meaning else { return nil }
        let trimmed = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
