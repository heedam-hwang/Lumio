import Foundation
import NaturalLanguage
import SwiftData
import Vision

struct DetectedSentence {
    let text: String
    let order: Int
}

enum OCRTextProcessor {
    nonisolated static func buildSentences(from lines: [String]) -> [DetectedSentence] {
        let rawText = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let combinedText = rawText.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !combinedText.isEmpty else { return [] }

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = combinedText
        tokenizer.setLanguage(.english)

        var results: [DetectedSentence] = []
        tokenizer.enumerateTokens(in: combinedText.startIndex..<combinedText.endIndex) { range, _ in
            let sentence = String(combinedText[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sentence.isEmpty else { return true }
            results.append(DetectedSentence(text: sentence, order: results.count + 1))
            return true
        }

        if results.isEmpty {
            results.append(DetectedSentence(text: combinedText, order: 1))
        }

        var normalizedResults: [DetectedSentence] = []
        for sentence in results {
            let splits = splitAfterTimeAbbreviations(sentence.text)
            for text in splits where !text.isEmpty {
                normalizedResults.append(
                    DetectedSentence(
                        text: text,
                        order: normalizedResults.count + 1
                    )
                )
            }
        }

        return normalizedResults.isEmpty ? results : normalizedResults
    }

    private nonisolated static func splitAfterTimeAbbreviations(_ text: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: #"\b(?:a\.m\.|p\.m\.)\s+(?=[A-Z])"#,
            options: [.caseInsensitive]
        ) else {
            return [text]
        }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: fullRange)
        guard !matches.isEmpty else { return [text] }

        var parts: [String] = []
        var start = 0
        for match in matches {
            let splitIndex = match.range.location + match.range.length
            let range = NSRange(location: start, length: splitIndex - start)
            let segment = nsText.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
            if !segment.isEmpty {
                parts.append(segment)
            }
            start = splitIndex
        }

        let tail = NSRange(location: start, length: nsText.length - start)
        let trailing = nsText.substring(with: tail).trimmingCharacters(in: .whitespacesAndNewlines)
        if !trailing.isEmpty {
            parts.append(trailing)
        }

        return parts
    }
}

enum VisionTextDetector {
    static func detect(from imageData: Data) async throws -> [DetectedSentence] {
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

            var lineTexts: [String] = []

            for observation in sorted {
                guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines),
                      !text.isEmpty else {
                    continue
                }
                lineTexts.append(text)
            }

            return OCRTextProcessor.buildSentences(from: lineTexts)
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

        let sentences = try await VisionTextDetector.detect(from: imageData)

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

        page.isTextAnalyzed = true
        try context.save()
    }
}
