import Foundation
import SwiftData

@Model
final class Page {
    @Attribute(.unique) var id: UUID
    var title: String?
    var sortOrder: Int?
    var createdAt: Date
    var imageData: Data?
    var isTextAnalyzed: Bool
    var book: Book?
    @Relationship(deleteRule: .cascade, inverse: \SentenceItem.page) var sentences: [SentenceItem]
    @Relationship(deleteRule: .cascade, inverse: \VocabularyItem.page) var vocabularies: [VocabularyItem]

    init(
        id: UUID = UUID(),
        title: String? = nil,
        sortOrder: Int? = nil,
        createdAt: Date = .now,
        imageData: Data? = nil,
        isTextAnalyzed: Bool = false,
        book: Book? = nil,
        sentences: [SentenceItem] = [],
        vocabularies: [VocabularyItem] = []
    ) {
        self.id = id
        self.title = title
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.imageData = imageData
        self.isTextAnalyzed = isTextAnalyzed
        self.book = book
        self.sentences = sentences
        self.vocabularies = vocabularies
    }
}
