import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var language: String
    @Relationship(deleteRule: .cascade, inverse: \Page.book) var pages: [Page]

    init(id: UUID = UUID(), title: String, language: String = "English", pages: [Page] = []) {
        self.id = id
        self.title = title
        self.language = language
        self.pages = pages
    }
}

@Model
final class Page {
    @Attribute(.unique) var id: UUID
    var title: String?
    var createdAt: Date
    var imageData: Data?
    var isTextAnalyzed: Bool
    var book: Book?
    @Relationship(deleteRule: .cascade, inverse: \SentenceItem.page) var sentences: [SentenceItem]
    @Relationship(deleteRule: .cascade, inverse: \VocabularyItem.page) var vocabularies: [VocabularyItem]

    init(
        id: UUID = UUID(),
        title: String? = nil,
        createdAt: Date = Date(),
        imageData: Data? = nil,
        isTextAnalyzed: Bool = false,
        book: Book? = nil,
        sentences: [SentenceItem] = [],
        vocabularies: [VocabularyItem] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.imageData = imageData
        self.isTextAnalyzed = isTextAnalyzed
        self.book = book
        self.sentences = sentences
        self.vocabularies = vocabularies
    }
}

@Model
final class SentenceItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var order: Int
    var meaning: String?
    var page: Page?

    init(
        id: UUID = UUID(),
        text: String,
        order: Int,
        meaning: String? = nil,
        page: Page? = nil
    ) {
        self.id = id
        self.text = text
        self.order = order
        self.meaning = meaning
        self.page = page
    }
}

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
        createdAt: Date = Date()
    ) {
        self.id = id
        self.word = word
        self.meaning = meaning
        self.pronunciation = pronunciation
        self.createdAt = createdAt
    }
}
