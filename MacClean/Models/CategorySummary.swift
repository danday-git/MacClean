import Foundation

struct CategorySummary: Identifiable, Equatable, Hashable, Sendable {
    var id: CleanupCategory { category }
    let category: CleanupCategory
    let totalBytes: Int64
    let eligibleBytes: Int64
    let itemCount: Int
}
