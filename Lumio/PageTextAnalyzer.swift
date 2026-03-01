import Foundation
import SwiftData
import Vision

struct DetectedSentence {
    let text: String
    let order: Int
}

struct DetectedWord {
    let word: String
    let order: Int
    let sentenceOrder: Int
}

enum OCRTextProcessor {
    nonisolated static func buildDetectedWords(from lines: [String]) -> [DetectedWord] {
        var words: [DetectedWord] = []
        var wordOrder = 1
        var seenWords = Set<String>()

        for (index, line) in lines.enumerated() {
            let sentenceOrder = index + 1
            for token in tokenize(line) {
                let normalized = token.lowercased()
                guard !seenWords.contains(normalized) else { continue }
                seenWords.insert(normalized)
                words.append(
                    DetectedWord(
                        word: normalized,
                        order: wordOrder,
                        sentenceOrder: sentenceOrder
                    )
                )
                wordOrder += 1
            }
        }

        return words
    }

    nonisolated static func tokenize(_ text: String) -> [String] {
        let pattern = "[A-Za-z]+(?:'[A-Za-z]+)?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        return matches.map { nsText.substring(with: $0.range) }
    }
}

enum VisionTextDetector {
    static func detect(from imageData: Data) async throws -> ([DetectedSentence], [DetectedWord]) {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(data: imageData)
            try handler.perform([request])

            let observations = request.results ?? []
            let sorted = observations.sorted {
                let lhsY = $0.boundingBox.midY
                let rhsY = $1.boundingBox.midY
                if abs(lhsY - rhsY) > 0.01 {
                    return lhsY > rhsY
                }
                return $0.boundingBox.minX < $1.boundingBox.minX
            }

            var sentences: [DetectedSentence] = []
            var lineTexts: [String] = []

            for (index, observation) in sorted.enumerated() {
                guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines),
                      !text.isEmpty else {
                    continue
                }

                let sentenceOrder = index + 1
                sentences.append(DetectedSentence(text: text, order: sentenceOrder))
                lineTexts.append(text)
            }

            let words = OCRTextProcessor.buildDetectedWords(from: lineTexts)
            return (sentences, words)
        }.value
    }
}

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

        let (sentences, words) = try await VisionTextDetector.detect(from: imageData)

        for item in page.sentences {
            context.delete(item)
        }

        for item in page.vocabularies {
            context.delete(item)
        }

        for sentence in sentences {
            let item = SentenceItem(
                text: sentence.text,
                order: sentence.order,
                page: page
            )
            context.insert(item)
        }

        for word in words {
            let item = VocabularyItem(
                word: word.word,
                order: word.order,
                sentenceOrder: word.sentenceOrder,
                page: page
            )
            context.insert(item)
        }

        page.isTextAnalyzed = true
        try context.save()
    }
}
