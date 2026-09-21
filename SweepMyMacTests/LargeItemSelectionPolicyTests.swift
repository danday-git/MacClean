import XCTest
@testable import SweepMyMac

@MainActor
final class LargeItemSelectionPolicyTests: XCTestCase {
    
    func testLargeItemsAreNeverAutoSelectedAsRecommended() {
        let selectionVM = CleanupSelectionViewModel()
        
        let largeVideo = ScanResultItem(
            name: "presentation_recording.mp4",
            path: URL(fileURLWithPath: "/Users/test/Movies/presentation_recording.mp4"),
            size: 15_000_000_000,
            category: .largeFiles,
            status: .possibleCandidate,
            confidence: .medium,
            isRegenerable: false
        )
        
        let largeRuntime = ScanResultItem(
            name: ".android",
            path: URL(fileURLWithPath: "/Users/test/.android"),
            size: 33_000_000_000,
            category: .largeFiles,
            status: .possibleCandidate,
            confidence: .medium,
            isRegenerable: false
        )
        
        let safeCache = ScanResultItem(
            name: "com.apple.Safari",
            path: URL(fileURLWithPath: "/Users/test/Library/Caches/com.apple.Safari"),
            size: 500_000_000,
            category: .caches,
            status: .knownCache,
            confidence: .high,
            isRegenerable: true
        )
        
        // 1. Verify recommendation policy
        XCTAssertFalse(selectionVM.isRecommended(largeVideo), "Large personal files must never be recommended for deletion")
        XCTAssertFalse(selectionVM.isRecommended(largeRuntime), "Large runtime directories must never be recommended for deletion")
        XCTAssertTrue(selectionVM.isRecommended(safeCache), "High confidence cache should be recommended")
        
        // 2. Verify selectRecommended
        let items: [CleanupCategory: [ScanResultItem]] = [
            .largeFiles: [largeVideo, largeRuntime],
            .caches: [safeCache]
        ]
        
        selectionVM.selectRecommended(in: items)
        
        XCTAssertFalse(selectionVM.isSelected(largeVideo), "Large video must not be selected by selectRecommended")
        XCTAssertFalse(selectionVM.isSelected(largeRuntime), "Large runtime data must not be selected by selectRecommended")
        XCTAssertTrue(selectionVM.isSelected(safeCache), "Safe cache should be selected")
        
        // 3. Verify selectAll(in:) also excludes medium-confidence large items
        selectionVM.clearSelection()
        selectionVM.selectAll(in: [largeVideo, largeRuntime, safeCache])
        
        XCTAssertFalse(selectionVM.isSelected(largeVideo), "Large items must not be bulk-selected via selectAll")
        XCTAssertFalse(selectionVM.isSelected(largeRuntime), "Large runtime items must not be bulk-selected via selectAll")
        XCTAssertTrue(selectionVM.isSelected(safeCache))
    }
}
