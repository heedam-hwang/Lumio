import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var language: String
    var coverImageData: Data?
    var placeholderPaletteSeed: Int?
    @Relationship(deleteRule: .cascade, inverse: \Page.book) var pages: [Page]

    init(
        id: UUID = UUID(),
        title: String,
        language: String = "English",
        coverImageData: Data? = nil,
        placeholderPaletteSeed: Int? = Int.random(in: 0..<1_000),
        pages: [Page] = []
    ) {
        self.id = id
        self.title = title
        self.language = language
        self.coverImageData = coverImageData
        self.placeholderPaletteSeed = placeholderPaletteSeed
        self.pages = pages
    }
}
