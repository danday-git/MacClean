import Foundation
import SwiftUI

@MainActor
final class CleanupSelectionViewModel: ObservableObject {
    @Published private(set) var selectedItems: Set<UUID> = []
    
    func toggle(_ item: ScanResultItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            // Reject protected, unknown, or low-confidence/informational items from selection
            guard item.status != .protected && item.status != .unknown && item.status != .notJunk && item.confidence != .low else {
                return
            }
            if item.status == .knownCache || item.status == .knownLeftover || item.status == .safeToDelete {
                selectedItems.insert(item.id)
            }
        }
    }
    
    func selectAll(in items: [ScanResultItem]) {
        for item in items {
            // Conservative default: only auto-select high-confidence candidates; exclude medium (manual review) and low (protected)
            guard item.confidence != .medium && item.confidence != .low else {
                continue
            }
            if item.status == .knownCache || item.status == .knownLeftover || item.status == .safeToDelete {
                selectedItems.insert(item.id)
            }
        }
    }
    
    func deselectAll(in items: [ScanResultItem]) {
        for item in items {
            selectedItems.remove(item.id)
        }
    }
    
    func isAllSelected(in items: [ScanResultItem]) -> Bool {
        let eligible = items.filter { isRecommended($0) }
        guard !eligible.isEmpty else { return false }
        return eligible.allSatisfy { selectedItems.contains($0.id) }
    }
    
    func isAllRecommendedSelected(from categoryItems: [CleanupCategory: [ScanResultItem]]) -> Bool {
        let allItems = categoryItems.values.flatMap { $0 }
        let eligible = allItems.filter { isRecommended($0) }
        guard !eligible.isEmpty else { return false }
        return eligible.allSatisfy { selectedItems.contains($0.id) }
    }
    
    func toggleSelectAll(in items: [ScanResultItem]) {
        if isAllSelected(in: items) {
            deselectAll(in: items)
        } else {
            selectAll(in: items)
        }
    }
    
    func clearSelection() {
        selectedItems.removeAll()
    }
    
    func isSelected(_ item: ScanResultItem) -> Bool {
        return selectedItems.contains(item.id)
    }
    
    func selectedSize(from allItems: [ScanResultItem]) -> Int64 {
        return allItems
            .filter { selectedItems.contains($0.id) }
            .reduce(0) { $0 + $1.size }
    }
    
    func selectedSize(from categoryItems: [CleanupCategory: [ScanResultItem]]) -> Int64 {
        let allItems = categoryItems.values.flatMap { $0 }
        return selectedSize(from: allItems)
    }
    
    func isRecommended(_ item: ScanResultItem) -> Bool {
        guard item.status != .protected && item.status != .unknown && item.status != .notJunk else {
            return false
        }
        // Exclude low and medium confidence items (medium requires manual review, low is protected/informational)
        guard item.confidence != .low && item.confidence != .medium else {
            return false
        }
        return item.status == .knownCache || item.status == .knownLeftover || item.status == .safeToDelete
    }

    func selectRecommended(in items: [ScanResultItem]) {
        for item in items {
            if isRecommended(item) {
                selectedItems.insert(item.id)
            }
        }
    }
    
    func selectRecommended(in categoryItems: [CleanupCategory: [ScanResultItem]]) {
        let allItems = categoryItems.values.flatMap { $0 }
        selectRecommended(in: allItems)
    }

    func recommendedSummary(from categoryItems: [CleanupCategory: [ScanResultItem]]) -> (count: Int, totalBytes: Int64) {
        let allItems = categoryItems.values.flatMap { $0 }
        let rec = allItems.filter { isRecommended($0) }
        return (rec.count, rec.reduce(0) { $0 + $1.size })
    }
}
