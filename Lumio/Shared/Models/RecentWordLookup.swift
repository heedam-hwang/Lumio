import Foundation
import SwiftData

@Model
final class RecentWordLookup {
    @Attribute(.unique) var id: UUID
    var word: String
    var meaning: String?
    var pronunciation: String?
    var editedMeaning: String?
    var lastViewedAt: Date

    init(
        id: UUID = UUID(),
        word: String,
        meaning: String? = nil,
        pronunciation: String? = nil,
        editedMeaning: String? = nil,
        lastViewedAt: Date = .now
    ) {
        self.id = id
        self.word = word
        self.meaning = meaning
        self.pronunciation = pronunciation
        self.editedMeaning = editedMeaning
        self.lastViewedAt = lastViewedAt
    }
}
