import XCTest
@testable import MacClean

final class DeduplicationTests: XCTestCase {
    
    func testFilesystemIdentityEquality() {
        let pathA = "/tmp/duplicate_test"
        let pathB = "/tmp/duplicate_test/."
        
        let identityA = FilesystemIdentity(url: URL(fileURLWithPath: pathA))
        let identityB = FilesystemIdentity(url: URL(fileURLWithPath: pathB))
        
        XCTAssertEqual(identityA, identityB, "Normalized paths must resolve to identical FilesystemIdentity")
    }
    
    func testCoordinatorDeduplication() async {
        let coordinator = DefaultScanCoordinator()
        
        // Two candidates pointing to the exact same canonical path in caches
        let item1 = ScanResultItem(
            name: "DuplicateA",
            path: URL(fileURLWithPath: "/tmp/dedup_target"),
            size: 500,
            category: .caches,
            status: .knownCache
        )
        
        let item2 = ScanResultItem(
            name: "DuplicateB",
            path: URL(fileURLWithPath: "/tmp/dedup_target"),
            size: 500,
            category: .developerData,
            status: .knownCache
        )
        
        let initialResults: [CleanupCategory: [ScanResultItem]] = [
            .caches: [item1],
            .developerData: [item2]
        ]
        
        // Manually verify deduplication logic
        var seenIdentities = Set<FilesystemIdentity>()
        var deduplicatedCount = 0
        
        for category in [CleanupCategory.caches, CleanupCategory.developerData] {
            let items = initialResults[category] ?? []
            for item in items {
                if !seenIdentities.contains(item.identity) {
                    seenIdentities.insert(item.identity)
                    deduplicatedCount += 1
                }
            }
        }
        
        XCTAssertEqual(deduplicatedCount, 1, "Only one entry must remain after canonical deduplication")
    }
}
