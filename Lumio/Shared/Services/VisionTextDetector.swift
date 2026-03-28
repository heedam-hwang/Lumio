import Foundation
import Vision

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
