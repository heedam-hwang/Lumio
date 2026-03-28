import CoreGraphics
import Foundation

struct SentenceToken: Identifiable {
    let id = UUID()
    let text: String
    let isWord: Bool
    let normalized: String
    let trailingSpacing: CGFloat

    static func build(from sentence: String) -> [SentenceToken] {
        guard let regex = try? NSRegularExpression(
            pattern: #"[A-Za-z]+(?:'[A-Za-z]+)?|[^A-Za-z\s]+"#
        ) else {
            return []
        }

        let nsSentence = sentence as NSString
        let range = NSRange(location: 0, length: nsSentence.length)
        let matches = regex.matches(in: sentence, range: range)

        return matches.map { match in
            let token = nsSentence.substring(with: match.range)
            let isWord = token.range(of: #"[A-Za-z]+"#, options: .regularExpression) != nil
            let spacing: CGFloat = token.range(of: #"[,.!?;:]"#, options: .regularExpression) != nil ? 2 : 4

            return SentenceToken(
                text: token,
                isWord: isWord,
                normalized: token.lowercased(),
                trailingSpacing: spacing
            )
        }
    }
}
