import Foundation
import SwiftData

@Model
final class VocabularyItem {
    @Attribute(.unique) var id: UUID
    var word: String
    var order: Int
    var sentenceOrder: Int
    var meaning: String?
    var pronunciation: String?
    var example: String?
    var page: Page?

    init(
        id: UUID = UUID(),
        word: String,
        order: Int = 0,
        sentenceOrder: Int = 0,
        meaning: String? = nil,
        pronunciation: String? = nil,
        example: String? = nil,
        page: Page? = nil
    ) {
        self.id = id
        self.word = word
        self.order = order
        self.sentenceOrder = sentenceOrder
        self.meaning = meaning
        self.pronunciation = pronunciation
        self.example = example
        self.page = page
    }
}
