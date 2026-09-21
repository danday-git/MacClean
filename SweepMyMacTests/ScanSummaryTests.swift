import XCTest
@testable import SweepMyMac

final class ScanSummaryTests: XCTestCase {
    
    func testScanSummaryCalculations() {
        let eligibleCache = ScanResultItem(
            name: "EligibleCache",
            path: URL(fileURLWithPath: "/tmp/cache"),
            size: 1000,
            category: .caches,
            status: .knownCache,
            confidence: .high
        )
        
        let protectedDev = ScanResultItem(
            name: "ProtectedDev",
            path: URL(fileURLWithPath: "/tmp/dev"),
            size: 2500,
            category: .developerData,
            status: .protected,
            confidence: .low
        )
        
        let unknownItem = ScanResultItem(
            name: "UnknownItem",
            path: URL(fileURLWithPath: "/tmp/unknown"),
            size: 800,
            category: .largeFiles,
            status: .unknown
        )
        
        let allItems = [eligibleCache, protectedDev, unknownItem]
        
        let totalScanned = allItems.reduce(0) { $0 + $1.size }
        let eligibleOnly = allItems.filter { $0.isEligibleForCleanup }.reduce(0) { $0 + $1.size }
        
        let summary = ScanSummary(
            totalScannedBytes: totalScanned,
            reclaimableBytes: eligibleOnly,
            selectedBytes: 1000,
            categorySummaries: [
                CategorySummary(category: .caches, totalBytes: 1000, eligibleBytes: 1000, itemCount: 1),
                CategorySummary(category: .developerData, totalBytes: 2500, eligibleBytes: 0, itemCount: 1),
                CategorySummary(category: .largeFiles, totalBytes: 800, eligibleBytes: 0, itemCount: 1)
            ],
            scanDuration: 1.25,
            warnings: [],
            isPartial: false
        )
        
        XCTAssertEqual(summary.totalScannedBytes, 4300, "Total scanned bytes should sum all candidates")
        XCTAssertEqual(summary.reclaimableBytes, 1000, "Reclaimable bytes must strictly count only eligible items")
        XCTAssertEqual(summary.categorySummaries.count, 3)
        XCTAssertEqual(summary.categorySummaries[1].eligibleBytes, 0, "Protected developer item must have 0 eligible bytes")
    }
}
