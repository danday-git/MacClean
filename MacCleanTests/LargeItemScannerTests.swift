import XCTest
@testable import MacClean

final class LargeItemScannerTests: XCTestCase {
    
    var tempDir: URL!
    let fileManager = FileManager.default
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = fileManager.temporaryDirectory.appendingPathComponent("MacCleanLargeItemTests_\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: tempDir)
        try super.tearDownWithError()
    }
    
    func testThresholdByteValues() {
        XCTAssertEqual(LargeItemThreshold.allLarge.minimumBytes, 1_073_741_824)
        XCTAssertEqual(LargeItemThreshold.veryLarge.minimumBytes, 5_368_709_120)
        XCTAssertEqual(LargeItemThreshold.huge.minimumBytes, 10_737_418_240)
    }
    
    func testLargeItemMetadataSafetyDefaults() {
        let dummyURL = tempDir.appendingPathComponent("sample_video.mov")
        let item = ScanResultItem(
            name: "sample_video.mov",
            path: dummyURL,
            size: 6_000_000_000,
            category: .largeFiles,
            status: .possibleCandidate,
            explanation: "Large user file (6 GB). Personal file.",
            confidence: .medium,
            isRegenerable: false,
            structuredExplanation: CleanupExplanation(
                whatIsIt: "Large personal file on your Mac.",
                whyDetected: "Size exceeds the 5+ GB discovery threshold.",
                canRegenerate: false,
                consequence: "Deleting this file will remove your personal document or media. Review carefully before moving to Trash."
            )
        )
        
        // Large items must never be marked as safeToDelete or knownCache
        XCTAssertEqual(item.status, .possibleCandidate)
        XCTAssertEqual(item.confidence, .medium)
        XCTAssertFalse(item.isRegenerable)
        XCTAssertFalse(item.isEligibleForCleanup)
        XCTAssertEqual(item.structuredExplanation?.canRegenerate, false)
    }
    
    func testThresholdFilteringLogic() {
        let item1GB = ScanResultItem(
            name: "file1.iso",
            path: tempDir.appendingPathComponent("file1.iso"),
            size: 2_000_000_000,
            category: .largeFiles,
            status: .possibleCandidate
        )
        let item7GB = ScanResultItem(
            name: "file2.iso",
            path: tempDir.appendingPathComponent("file2.iso"),
            size: 7_000_000_000,
            category: .largeFiles,
            status: .possibleCandidate
        )
        let item12GB = ScanResultItem(
            name: "file3.iso",
            path: tempDir.appendingPathComponent("file3.iso"),
            size: 12_000_000_000,
            category: .largeFiles,
            status: .possibleCandidate
        )
        
        let allItems = [item1GB, item7GB, item12GB]
        
        // At 1+ GB: all 3 items match
        let threshold1 = LargeItemThreshold.allLarge
        let filtered1 = allItems.filter { $0.size >= threshold1.minimumBytes }
        XCTAssertEqual(filtered1.count, 3)
        
        // At 5+ GB: item7GB and item12GB match
        let threshold5 = LargeItemThreshold.veryLarge
        let filtered5 = allItems.filter { $0.size >= threshold5.minimumBytes }
        XCTAssertEqual(filtered5.count, 2)
        
        // At 10+ GB: only item12GB matches
        let threshold10 = LargeItemThreshold.huge
        let filtered10 = allItems.filter { $0.size >= threshold10.minimumBytes }
        XCTAssertEqual(filtered10.count, 1)
        XCTAssertEqual(filtered10.first?.name, "file3.iso")
    }
    
    func test500MBThresholdValue() {
        XCTAssertEqual(LargeItemThreshold.large500MB.minimumBytes, 524_288_000)
    }
    
    @MainActor
    func testDashboardViewModelFiltersLargeFilesBySelectedThreshold() {
        let vm = DashboardViewModel()
        let item600MB = ScanResultItem(
            name: "video_600mb.mp4",
            path: tempDir.appendingPathComponent("video_600mb.mp4"),
            size: 600_000_000,
            category: .largeFiles,
            status: .possibleCandidate
        )
        let item2GB = ScanResultItem(
            name: "installer_2gb.dmg",
            path: tempDir.appendingPathComponent("installer_2gb.dmg"),
            size: 2_000_000_000,
            category: .largeFiles,
            status: .possibleCandidate
        )
        let item6GB = ScanResultItem(
            name: "archive_6gb.zip",
            path: tempDir.appendingPathComponent("archive_6gb.zip"),
            size: 6_000_000_000,
            category: .largeFiles,
            status: .possibleCandidate
        )
        
        vm.categoryItems[.largeFiles] = [item600MB, item2GB, item6GB]
        
        // Threshold: 500+ MB -> all 3
        vm.selectedThreshold = .large500MB
        XCTAssertEqual(vm.filteredAndSortedItems(for: .largeFiles).count, 3)
        
        // Threshold: 1+ GB -> 2 items (2GB and 6GB)
        vm.selectedThreshold = .allLarge
        let items1GB = vm.filteredAndSortedItems(for: .largeFiles)
        XCTAssertEqual(items1GB.count, 2)
        XCTAssertFalse(items1GB.contains { $0.name == "video_600mb.mp4" })
        
        // Threshold: 5+ GB -> 1 item (6GB)
        vm.selectedThreshold = .veryLarge
        let items5GB = vm.filteredAndSortedItems(for: .largeFiles)
        XCTAssertEqual(items5GB.count, 1)
        XCTAssertEqual(items5GB.first?.name, "archive_6gb.zip")
        
        // Threshold: 10+ GB -> 0 items
        vm.selectedThreshold = .huge
        XCTAssertEqual(vm.filteredAndSortedItems(for: .largeFiles).count, 0)
    }
}
