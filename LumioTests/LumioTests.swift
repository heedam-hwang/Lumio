import SwiftData
import XCTest
@testable import Lumio

final class OCRTextProcessorTests: XCTestCase {
    func testBuildSentencesSplitsBySentencePunctuation() {
        let lines = [
            "Hello world.",
            "How are you? I am fine!"
        ]

        let sentences = OCRTextProcessor.buildSentences(from: lines)

        XCTAssertEqual(sentences.map(\.text), ["Hello world.", "How are you?", "I am fine!"])
        XCTAssertEqual(sentences.map(\.order), [1, 2, 3])
    }

    func testBuildSentencesMergesLineBreaksIntoSingleSentenceWhenNeeded() {
        let lines = [
            "This is first line",
            "continued same sentence"
        ]

        let sentences = OCRTextProcessor.buildSentences(from: lines)

        XCTAssertEqual(sentences.map(\.text), ["This is first line continued same sentence"])
        XCTAssertEqual(sentences.map(\.order), [1])
    }

    func testBuildSentencesSplitsAbbreviationAndFollowingSentences() {
        let lines = [
            "7:07 a.m. Somewhere in North Dakota. Abroad Amtrak's Empire Builder, en route from Chicago to Portland, Oregon."
        ]

        let sentences = OCRTextProcessor.buildSentences(from: lines)

        XCTAssertEqual(
            sentences.map(\.text),
            [
                "7:07 a.m.",
                "Somewhere in North Dakota.",
                "Abroad Amtrak's Empire Builder, en route from Chicago to Portland, Oregon."
            ]
        )
        XCTAssertEqual(sentences.map(\.order), [1, 2, 3])
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
