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

final class SentenceTokenTests: XCTestCase {
    func testBuildCreatesWordAndPunctuationTokensInOrder() {
        let tokens = SentenceToken.build(from: "Hello, world!")

        XCTAssertEqual(tokens.map(\.text), ["Hello", ",", "world", "!"])
        XCTAssertEqual(tokens.map(\.isWord), [true, false, true, false])
        XCTAssertEqual(tokens.map(\.normalized), ["hello", ",", "world", "!"])
    }
}

@MainActor
final class HomeUploadCoordinatorTests: XCTestCase {
    func testResolveTargetBookCreatesNewBookForNewMode() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let coordinator = HomeUploadCoordinator()

        let resolved = coordinator.resolveTargetBook(
            mode: .new,
            selectedBook: nil,
            newBookTitle: "New Book",
            modelContext: context
        )

        XCTAssertEqual(resolved.title, "New Book")
    }

    func testResolveTargetBookFallsBackToUnclassifiedWhenNewTitleIsEmpty() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let coordinator = HomeUploadCoordinator()

        let resolved = coordinator.resolveTargetBook(
            mode: .new,
            selectedBook: nil,
            newBookTitle: "   ",
            modelContext: context
        )

        XCTAssertEqual(resolved.title, "분류되지 않음")
    }
}

@MainActor
final class WordLookupModelTests: XCTestCase {
    func testToggleVocabularyBookmarkSavesAndDeletesWord() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let model = WordLookupModel(word: VocabularyItem(word: "hello"))

        model.toggleVocabularyBookmark(context: context)
        XCTAssertTrue(model.isSaved)
        XCTAssertEqual(try context.fetch(FetchDescriptor<SavedVocabulary>()).count, 1)

        model.toggleVocabularyBookmark(context: context)
        XCTAssertFalse(model.isSaved)
        XCTAssertEqual(try context.fetch(FetchDescriptor<SavedVocabulary>()).count, 0)
    }

    func testApplyEditedMeaningUpdatesRecentAndSavedVocabulary() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let model = WordLookupModel(word: VocabularyItem(word: "hello"))

        model.applyTranslation("안녕하세요")
        model.toggleVocabularyBookmark(context: context)
        model.applyEditedMeaning("수정된 뜻", context: context)
        model.recordRecentLookup(context: context)

        let savedItem = try XCTUnwrap(WordLookupStore.fetchSavedVocabulary(word: "hello", context: context))
        let recentItem = try XCTUnwrap(WordLookupStore.fetchRecentLookup(word: "hello", context: context))

        XCTAssertEqual(model.currentMeaning, "수정된 뜻")
        XCTAssertEqual(savedItem.meaning, "수정된 뜻")
        XCTAssertEqual(recentItem.meaning, "수정된 뜻")
        XCTAssertEqual(recentItem.editedMeaning, "수정된 뜻")
    }
}

@MainActor
final class WordLookupStoreTests: XCTestCase {
    func testUpsertRecentLookupMovesDuplicateWordToTop() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        _ = try WordLookupStore.upsertRecentLookup(
            word: "apple",
            meaning: "사과",
            viewedAt: Date(timeIntervalSince1970: 10),
            context: context
        )
        _ = try WordLookupStore.upsertRecentLookup(
            word: "banana",
            meaning: "바나나",
            viewedAt: Date(timeIntervalSince1970: 20),
            context: context
        )
        _ = try WordLookupStore.upsertRecentLookup(
            word: "apple",
            meaning: "사과 수정",
            viewedAt: Date(timeIntervalSince1970: 30),
            context: context
        )

        let items = try context.fetch(
            FetchDescriptor<RecentWordLookup>(
                sortBy: [SortDescriptor(\.lastViewedAt, order: .reverse)]
            )
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.map(\.word), ["apple", "banana"])
        XCTAssertEqual(items.first?.meaning, "사과 수정")
    }

    func testUpsertRecentLookupKeepsOnlyLatestThirtyItems() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        for index in 0...30 {
            _ = try WordLookupStore.upsertRecentLookup(
                word: "word\(index)",
                meaning: "meaning\(index)",
                viewedAt: Date(timeIntervalSince1970: TimeInterval(index)),
                context: context
            )
        }

        let items = try context.fetch(
            FetchDescriptor<RecentWordLookup>(
                sortBy: [SortDescriptor(\.lastViewedAt, order: .reverse)]
            )
        )

        XCTAssertEqual(items.count, 30)
        XCTAssertEqual(items.first?.word, "word30")
        XCTAssertEqual(items.last?.word, "word1")
    }
}

@MainActor
final class PageTextAnalyzerTests: XCTestCase {
    func testAnalyzeWithoutImageMarksPageAsAnalyzed() async throws {
        let container = try makeInMemoryContainer()
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

final class PageSortingTests: XCTestCase {
    func testDisplayOrderPrefersSortOrderThenCreatedAtThenIdentifier() {
        let earlier = Page(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "A",
            sortOrder: 1,
            createdAt: .distantFuture
        )
        let later = Page(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "B",
            sortOrder: 2,
            createdAt: .distantPast
        )

        XCTAssertTrue(PageSorting.areInDisplayOrder(earlier, later))

        let sameOrderEarlierDate = Page(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            title: "C",
            sortOrder: 2,
            createdAt: .distantPast
        )

        XCTAssertTrue(PageSorting.areInDisplayOrder(sameOrderEarlierDate, later))
    }
}

private func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([Book.self, Page.self, SentenceItem.self, VocabularyItem.self, SavedVocabulary.self, RecentWordLookup.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [configuration])
}
