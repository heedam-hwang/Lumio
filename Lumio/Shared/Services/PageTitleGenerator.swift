import Foundation

enum PageTitleGenerator {
    static func resolvedTitle(input: String, date: Date = .now) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultTitle(for: date) : trimmed
    }

    static func defaultTitle(for date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "y-MM-dd HH:mm:ss"
        return "페이지 \(formatter.string(from: date))"
    }
}
