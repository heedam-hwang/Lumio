import SwiftData
import XCTest
@testable import Lumio

final class OCRTextProcessorTests: XCTestCase {
    func testTokenizeExtractsEnglishWordsAndApostrophes() {
        let tokens = OCRTextProcessor.tokenize("Hello, reader's world! 123")

        XCTAssertEqual(tokens, ["Hello", "reader's", "world"])
    }

    func testBuildDetectedWordsDeduplicatesWithinPage() {
        let lines = [
            "Apple banana apple",
            "BANANA grape"
        ]

        let words = OCRTextProcessor.buildDetectedWords(from: lines)

        XCTAssertEqual(words.map(\.word), ["apple", "banana", "grape"])
        XCTAssertEqual(words.map(\.order), [1, 2, 3])
        XCTAssertEqual(words.map(\.sentenceOrder), [1, 1, 2])
    }
}

@MainActor
final class PageTextAnalyzerTests: XCTestCase {
    func testAnalyzeWithoutImageMarksPageAsAnalyzed() async throws {
        let schema = Schema([Book.self, Page.self, SentenceItem.self, VocabularyItem.self, SavedVocabulary.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let book = Book(title: "Test Book")
        let page = Page(title: "p1", imageData: nil, book: book)
        context.insert(book)
        context.insert(page)
        try context.save()

        XCTAssertFalse(page.isTextAnalyzed)

        try await PageTextAnalyzer.analyzeIfNeeded(page: page, context: context)

        XCTAssertTrue(page.isTextAnalyzed)
        XCTAssertTrue(page.sentences.isEmpty)
        XCTAssertTrue(page.vocabularies.isEmpty)
    }
}
