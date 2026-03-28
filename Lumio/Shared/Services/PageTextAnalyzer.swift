import Foundation
import SwiftData

enum PageTextAnalyzer {
    @MainActor
    static func analyzeIfNeeded(page: Page, context: ModelContext, force: Bool = false) async throws {
        if !force && page.isTextAnalyzed {
            return
        }

        guard let imageData = page.imageData else {
            page.isTextAnalyzed = true
            try context.save()
            return
        }

        let sentences = try await VisionTextDetector.detect(from: imageData)

        for item in page.sentences {
            context.delete(item)
        }

        for item in page.vocabularies {
            context.delete(item)
        }

        for sentence in sentences {
            let item = SentenceItem(text: sentence.text, order: sentence.order, page: page)
            context.insert(item)
        }

        page.isTextAnalyzed = true
        try context.save()
    }
}
