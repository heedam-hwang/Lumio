import Foundation

enum BookClassificationMode: String, CaseIterable, Identifiable {
    case unclassified
    case existing
    case new

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unclassified:
            "분류하지 않음"
        case .existing:
            "기존 책 선택"
        case .new:
            "새 책 생성"
        }
    }
}
