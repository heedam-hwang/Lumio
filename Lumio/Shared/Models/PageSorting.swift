import Foundation

enum PageSorting {
    static func areInDisplayOrder(_ lhs: Page, _ rhs: Page) -> Bool {
        let lhsOrder = lhs.sortOrder ?? .max
        let rhsOrder = rhs.sortOrder ?? .max

        if lhsOrder != rhsOrder {
            return lhsOrder < rhsOrder
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }
}
