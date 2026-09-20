import Foundation

struct CategoryCleanupStat: Equatable, Sendable, Identifiable {
    var id: String { category.rawValue }
    let category: CleanupCategory
    let count: Int
    let bytes: Int64
    
    init(category: CleanupCategory, count: Int, bytes: Int64) {
        self.category = category
        self.count = count
        self.bytes = bytes
    }
}

struct CleanupBeforeAfter: Equatable, Sendable {
    let timestamp: Date
    let beforeFreeBytes: Int64
    let afterFreeBytes: Int64
    let beforeUsedBytes: Int64
    let afterUsedBytes: Int64
    let beforeReclaimableBytes: Int64
    let afterReclaimableBytes: Int64
    let bytesMoved: Int64
    let itemsMovedCount: Int
    let itemsFailedCount: Int
    let categoryStats: [CategoryCleanupStat]
    
    init(
        timestamp: Date = Date(),
        beforeFreeBytes: Int64,
        afterFreeBytes: Int64,
        beforeUsedBytes: Int64,
        afterUsedBytes: Int64,
        beforeReclaimableBytes: Int64,
        afterReclaimableBytes: Int64,
        bytesMoved: Int64,
        itemsMovedCount: Int,
        itemsFailedCount: Int,
        categoryStats: [CategoryCleanupStat] = []
    ) {
        self.timestamp = timestamp
        self.beforeFreeBytes = beforeFreeBytes
        self.afterFreeBytes = afterFreeBytes
        self.beforeUsedBytes = beforeUsedBytes
        self.afterUsedBytes = afterUsedBytes
        self.beforeReclaimableBytes = beforeReclaimableBytes
        self.afterReclaimableBytes = afterReclaimableBytes
        self.bytesMoved = bytesMoved
        self.itemsMovedCount = itemsMovedCount
        self.itemsFailedCount = itemsFailedCount
        self.categoryStats = categoryStats
    }
    
    /// The effective or projected free space after cleanup.
    /// On APFS, moving files to ~/.Trash might not immediately update the volumeAvailableCapacity
    /// until Trash is emptied in Finder. Therefore, projected free space reflects the disk space freed.
    var effectiveAfterFreeBytes: Int64 {
        max(afterFreeBytes, beforeFreeBytes + bytesMoved)
    }
    
    /// The effective or projected used space after cleanup.
    var effectiveAfterUsedBytes: Int64 {
        min(afterUsedBytes, max(0, beforeUsedBytes - bytesMoved))
    }
    
    /// Total storage gained (freed up) from this cleanup.
    var freeSpaceGain: Int64 {
        max(bytesMoved, afterFreeBytes - beforeFreeBytes)
    }
    
    /// Reclaimable reduction (how much candidate backlog was cleaned).
    var reclaimableReduction: Int64 {
        max(0, beforeReclaimableBytes - afterReclaimableBytes)
    }
}
