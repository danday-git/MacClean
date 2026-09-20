import Foundation

struct CleanupCandidate: Identifiable, Hashable, Sendable {
    var id: UUID { item.id }
    let item: ScanResultItem
    var isSelected: Bool
    
    init(item: ScanResultItem, isSelected: Bool = false) {
        self.item = item
        self.isSelected = isSelected
    }
}
