import XCTest
@testable import SweepMyMac

final class CleanupConfidenceTierTests: XCTestCase {
    
    func testTierMappingForDifferentCandidates() {
        // 1. High confidence cache -> safeToClean
        let cacheItem = ScanResultItem(
            name: "Claude Cache",
            path: URL(fileURLWithPath: "/Users/test/Library/Caches/Claude"),
            size: 497_000_000,
            category: .caches,
            status: .knownCache,
            confidence: .high
        )
        XCTAssertEqual(cacheItem.confidenceTier, .safeToClean)
        XCTAssertEqual(cacheItem.confidenceTier.badgeLabel, "Safe to clean")
        XCTAssertEqual(cacheItem.whyDialogTitle, "Why can SweepMyMac clean this?")
        XCTAssertTrue(cacheItem.consequenceExplanationText.contains("Trash"))
        
        // 2. High confidence leftover -> safeToClean
        let leftoverItem = ScanResultItem(
            name: "Slack",
            path: URL(fileURLWithPath: "/Users/test/Library/Application Support/Slack"),
            size: 1_200_000_000,
            category: .appLeftovers,
            status: .knownLeftover,
            ownerApplication: "Slack",
            confidence: .high
        )
        XCTAssertEqual(leftoverItem.confidenceTier, .safeToClean)
        XCTAssertTrue(leftoverItem.humanExplanationText.contains("no longer installed"))
        
        // 3. Medium confidence developer cache -> needsReview
        let mavenItem = ScanResultItem(
            name: "repository",
            path: URL(fileURLWithPath: "/Users/test/.m2/repository"),
            size: 2_400_000_000,
            category: .developerData,
            status: .possibleCandidate,
            confidence: .medium
        )
        XCTAssertEqual(mavenItem.confidenceTier, .needsReview)
        XCTAssertEqual(mavenItem.confidenceTier.badgeLabel, "Review manually")
        XCTAssertEqual(mavenItem.whyDialogTitle, "Why does this require review?")
        
        // 4. Large personal file -> needsReview
        let largeFileItem = ScanResultItem(
            name: "screen_recording.mov",
            path: URL(fileURLWithPath: "/Users/test/Movies/screen_recording.mov"),
            size: 8_200_000_000,
            category: .largeFiles,
            status: .possibleCandidate,
            confidence: .medium
        )
        XCTAssertEqual(largeFileItem.confidenceTier, .needsReview)
        XCTAssertEqual(largeFileItem.whyDialogTitle, "Why does this require review?")
        
        // 5. Xcode Archives -> protected
        let archiveItem = ScanResultItem(
            name: "MyProject 2026-09-01.xcarchive",
            path: URL(fileURLWithPath: "/Users/test/Library/Developer/Xcode/Archives/2026-09-01/MyProject.xcarchive"),
            size: 5_100_000_000,
            category: .developerData,
            status: .protected,
            developerType: .xcodeArchives,
            confidence: .low
        )
        XCTAssertEqual(archiveItem.confidenceTier, .protected)
        XCTAssertEqual(archiveItem.confidenceTier.badgeLabel, "Protected")
        XCTAssertEqual(archiveItem.whyDialogTitle, "Why is this item protected?")
        XCTAssertTrue(archiveItem.humanExplanationText.contains("release builds"))
        XCTAssertFalse(archiveItem.isEligibleForCleanup)
    }
    
    func testExplanationTextsContainSafetyReassurance() {
        let cacheItem = ScanResultItem(
            name: "Safari Cache",
            path: URL(fileURLWithPath: "/Users/test/Library/Caches/Safari"),
            size: 200_000_000,
            category: .caches,
            status: .knownCache,
            confidence: .high
        )
        
        XCTAssertTrue(cacheItem.consequenceExplanationText.contains("Trash"), "Safe items must reassure user that files move to Trash")
        XCTAssertTrue(cacheItem.consequenceExplanationText.contains("restore"), "Safe items must reassure user that files can be restored")
    }
}
