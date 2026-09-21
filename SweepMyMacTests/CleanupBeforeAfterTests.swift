import XCTest
@testable import SweepMyMac

private final class MockTrashManager: TrashManaging, @unchecked Sendable {
    var itemsToSucceed: Set<UUID> = []
    
    func moveToTrash(items: [ScanResultItem], progress: @escaping @Sendable (Int, Int) -> Void) async -> [TrashOperationResult] {
        var results: [TrashOperationResult] = []
        for (index, item) in items.enumerated() {
            if itemsToSucceed.contains(item.id) {
                results.append(TrashOperationResult(sourceItem: item, status: .moved, error: nil))
            } else {
                results.append(TrashOperationResult(sourceItem: item, status: .rejected, error: nil))
            }
            progress(index + 1, items.count)
        }
        return results
    }
}

final class CleanupBeforeAfterTests: XCTestCase {
    
    func testCleanupBeforeAfterCalculations() {
        let stat1 = CategoryCleanupStat(category: .caches, count: 5, bytes: 2_000_000_000)
        let stat2 = CategoryCleanupStat(category: .appLeftovers, count: 2, bytes: 500_000_000)
        
        // Scenario 1: APFS latency where volumeAvailableCapacity has not updated yet
        let summary1 = CleanupBeforeAfter(
            timestamp: Date(),
            beforeFreeBytes: 50_000_000_000,
            afterFreeBytes: 50_000_000_000, // unchanged due to ~/.Trash storage
            beforeUsedBytes: 200_000_000_000,
            afterUsedBytes: 200_000_000_000,
            beforeReclaimableBytes: 4_000_000_000,
            afterReclaimableBytes: 1_500_000_000,
            bytesMoved: 2_500_000_000,
            itemsMovedCount: 7,
            itemsFailedCount: 0,
            categoryStats: [stat1, stat2]
        )
        
        XCTAssertEqual(summary1.bytesMoved, 2_500_000_000)
        XCTAssertEqual(summary1.effectiveAfterFreeBytes, 52_500_000_000, "Projected free space should be beforeFreeBytes + bytesMoved")
        XCTAssertEqual(summary1.effectiveAfterUsedBytes, 197_500_000_000, "Projected used space should be beforeUsedBytes - bytesMoved")
        XCTAssertEqual(summary1.freeSpaceGain, 2_500_000_000)
        XCTAssertEqual(summary1.reclaimableReduction, 2_500_000_000)
        XCTAssertEqual(summary1.itemsMovedCount, 7)
        XCTAssertEqual(summary1.itemsFailedCount, 0)
        XCTAssertEqual(summary1.categoryStats.count, 2)
        
        // Scenario 2: Filesystem storage already reflects increased space
        let summary2 = CleanupBeforeAfter(
            timestamp: Date(),
            beforeFreeBytes: 50_000_000_000,
            afterFreeBytes: 53_000_000_000, // 3 GB increase
            beforeUsedBytes: 200_000_000_000,
            afterUsedBytes: 197_000_000_000,
            beforeReclaimableBytes: 3_000_000_000,
            afterReclaimableBytes: 0,
            bytesMoved: 3_000_000_000,
            itemsMovedCount: 5,
            itemsFailedCount: 0,
            categoryStats: [stat1]
        )
        
        XCTAssertEqual(summary2.effectiveAfterFreeBytes, 53_000_000_000)
        XCTAssertEqual(summary2.freeSpaceGain, 3_000_000_000)
        XCTAssertEqual(summary2.reclaimableReduction, 3_000_000_000)
    }
    
    @MainActor
    func testDashboardViewModelCleanupLifecycle() async {
        let item1 = ScanResultItem(
            name: "CacheItem",
            path: URL(fileURLWithPath: "/tmp/cache_item"),
            size: 1_200_000_000,
            category: CleanupCategory.caches,
            status: .knownCache,
            confidence: .high
        )
        let item2 = ScanResultItem(
            name: "LeftoverItem",
            path: URL(fileURLWithPath: "/tmp/leftover_item"),
            size: 300_000_000,
            category: CleanupCategory.appLeftovers,
            status: .knownLeftover,
            confidence: .high
        )
        
        let vm = DashboardViewModel(scanner: MockScanner(), scanCoordinator: DefaultScanCoordinator())
        vm.summary = StorageSummary(totalSpace: 250_000_000_000, usedSpace: 150_000_000_000, reclaimableSpace: 1_500_000_000)
        vm.categoryItems = [
            CleanupCategory.caches: [item1],
            CleanupCategory.appLeftovers: [item2]
        ]
        
        let mockTrash = MockTrashManager()
        mockTrash.itemsToSucceed = [item1.id, item2.id]
        
        let plan = CleanupPlan(items: [item1, item2], totalSize: 1_500_000_000, warnings: [])
        
        XCTAssertNil(vm.latestCleanupResult)
        XCTAssertFalse(vm.showCleanupSuccessBanner)
        
        await vm.performCleanup(plan: plan, trashManager: mockTrash)
        
        XCTAssertNotNil(vm.latestCleanupResult, "latestCleanupResult must be populated after cleanup")
        XCTAssertTrue(vm.showCleanupSuccessBanner, "Success banner must be visible after cleanup")
        
        if let result = vm.latestCleanupResult {
            XCTAssertEqual(result.bytesMoved, 1_500_000_000)
            XCTAssertEqual(result.itemsMovedCount, 2)
            XCTAssertEqual(result.itemsFailedCount, 0)
            XCTAssertEqual(result.categoryStats.count, 2)
        }
        
        // Test banner dismissal
        vm.dismissCleanupBanner()
        XCTAssertFalse(vm.showCleanupSuccessBanner, "Banner should be hidden when dismissed")
    }
}
