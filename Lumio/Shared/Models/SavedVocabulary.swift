import Foundation
import SwiftData

@Model
final class SavedVocabulary {
    @Attribute(.unique) var id: UUID
    var word: String
    var meaning: String?
    var pronunciation: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        word: String,
        meaning: String? = nil,
        pronunciation: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.word = word
        self.meaning = meaning
        self.pronunciation = pronunciation
        self.createdAt = createdAt
    }
}
