import Foundation

enum HomeRoute: Hashable {
    case book(UUID)
    case page(bookID: UUID, pageID: UUID)
}
