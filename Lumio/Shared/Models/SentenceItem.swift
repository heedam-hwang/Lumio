import Foundation
import SwiftData

@Model
final class SentenceItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var order: Int
    var meaning: String?
    var page: Page?

    init(
        id: UUID = UUID(),
        text: String,
        order: Int,
        meaning: String? = nil,
        page: Page? = nil
    ) {
        self.id = id
        self.text = text
        self.order = order
        self.meaning = meaning
        self.page = page
    }
}
