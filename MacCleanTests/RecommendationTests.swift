import XCTest
@testable import MacClean

@MainActor
final class RecommendationTests: XCTestCase {
    
    func testRecommendationPolicy() {
        let selectionVM = CleanupSelectionViewModel()
        
        let highEligible = ScanResultItem(
            name: "HighEligibleCache",
            path: URL(fileURLWithPath: "/tmp/high_eligible"),
            size: 500,
            category: .caches,
            status: .knownCache,
            confidence: .high
        )
        
        let mediumReview = ScanResultItem(
            name: "MediumReviewCache",
            path: URL(fileURLWithPath: "/tmp/medium_review"),
            size: 300,
            category: .developerData,
            status: .knownCache,
            confidence: .medium
        )
        
        let lowProtected = ScanResultItem(
            name: "LowProtectedData",
            path: URL(fileURLWithPath: "/tmp/low_protected"),
            size: 1000,
            category: .developerData,
            status: .protected,
            confidence: .low
        )
        
        let highProtected = ScanResultItem(
            name: "HighProtected",
            path: URL(fileURLWithPath: "/tmp/high_protected"),
            size: 200,
            category: .caches,
            status: .protected,
            confidence: .high
        )
        
        let unknownItem = ScanResultItem(
            name: "UnknownItem",
            path: URL(fileURLWithPath: "/tmp/unknown"),
            size: 150,
            category: .caches,
            status: .unknown,
            confidence: .high
        )
        
        let allItems = [highEligible, mediumReview, lowProtected, highProtected, unknownItem]
        
        // Check recommendation predicates
        XCTAssertTrue(selectionVM.isRecommended(highEligible), "High confidence eligible item must be recommended")
        XCTAssertFalse(selectionVM.isRecommended(mediumReview), "Medium confidence item must NOT be recommended")
        XCTAssertFalse(selectionVM.isRecommended(lowProtected), "Low confidence protected item must NOT be recommended")
        XCTAssertFalse(selectionVM.isRecommended(highProtected), "Protected item must NOT be recommended even with high confidence")
        XCTAssertFalse(selectionVM.isRecommended(unknownItem), "Unknown item must NOT be recommended")
        
        // Execute selectRecommended
        selectionVM.selectRecommended(in: allItems)
        
        XCTAssertTrue(selectionVM.isSelected(highEligible), "High eligible must be selected")
        XCTAssertFalse(selectionVM.isSelected(mediumReview), "Medium review must NOT be selected")
        XCTAssertFalse(selectionVM.isSelected(lowProtected), "Low protected must NOT be selected")
        XCTAssertFalse(selectionVM.isSelected(highProtected), "High protected must NOT be selected")
        XCTAssertFalse(selectionVM.isSelected(unknownItem), "Unknown must NOT be selected")
        
        // Summary verification
        let summary = selectionVM.recommendedSummary(from: [.caches: [highEligible, highProtected, unknownItem], .developerData: [mediumReview, lowProtected]])
        XCTAssertEqual(summary.count, 1)
        XCTAssertEqual(summary.totalBytes, 500)
    }
}
