import XCTest
@testable import SweepMyMac

final class ReleaseHardeningTests: XCTestCase {
    
    var tempHome: URL!
    let fileManager = FileManager.default
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let uniqueID = UUID().uuidString
        tempHome = fileManager.temporaryDirectory.appendingPathComponent("SweepMyMacHardening_\(uniqueID)")
        try fileManager.createDirectory(at: tempHome, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: tempHome)
        try super.tearDownWithError()
    }
    
    // MARK: - 1. Cancellation Completes in < 1 Second
    @MainActor
    func testConcurrentScanCancellationSpeed() async {
        let coordinator = DefaultScanCoordinator()
        let vm = DashboardViewModel(scanCoordinator: coordinator)
        
        let start = CFAbsoluteTimeGetCurrent()
        vm.scan()
        
        // Wait a brief moment to let scanning tasks spawn
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        vm.cancelScan()
        
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertFalse(vm.isScanning, "ViewModel should immediately mark scanning as false")
        XCTAssertEqual(vm.currentScanningStatus, "Scan cancelled")
        XCTAssertLessThan(elapsed, 1.0, "Scan cancellation must complete in under 1 second (took \(elapsed)s)")
    }
    
    // MARK: - 2. TOCTOU Symlink Replacement Attack Prevention
    func testTOCTOUSymlinkReplacementAttackPrevention() async throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches/com.attack.app")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let targetFile = cacheFolder.appendingPathComponent("real_cache.tmp")
        try "initial-cache-content".write(to: targetFile, atomically: true, encoding: .utf8)
        
        let candidate = ScanResultItem(
            name: "real_cache.tmp",
            path: targetFile,
            size: 21,
            category: .caches,
            status: .knownCache,
            confidence: .high
        )
        
        // Now simulate attacker replacing the candidate with a symlink right before TrashManager runs
        try fileManager.removeItem(at: targetFile)
        try fileManager.createSymbolicLink(at: targetFile, withDestinationURL: URL(fileURLWithPath: "/etc/hosts"))
        
        let validator = DefaultCleanupValidator(homeDirectory: tempHome)
        let trashManager = DefaultTrashManager(validator: validator, homeDirectory: tempHome)
        
        let results = await trashManager.moveToTrash(items: [candidate]) { _, _ in }
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].status, .rejected, "Symlink replacement must be detected and rejected by double-validation")
    }
    
    // MARK: - 3. Disappearing File Does Not Abort Batch
    func testDisappearingFileDoesNotAbortBatch() async throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches/com.batch.test")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let file1 = cacheFolder.appendingPathComponent("disappearing.tmp")
        let file2 = cacheFolder.appendingPathComponent("valid.tmp")
        
        try "data1".write(to: file1, atomically: true, encoding: .utf8)
        try "data2".write(to: file2, atomically: true, encoding: .utf8)
        
        let item1 = ScanResultItem(name: "disappearing.tmp", path: file1, size: 5, category: .caches, status: .knownCache, confidence: .high)
        let item2 = ScanResultItem(name: "valid.tmp", path: file2, size: 5, category: .caches, status: .knownCache, confidence: .high)
        
        // Delete item 1 before TrashManager processes it
        try fileManager.removeItem(at: file1)
        
        let validator = DefaultCleanupValidator(homeDirectory: tempHome)
        let trashManager = DefaultTrashManager(validator: validator, homeDirectory: tempHome)
        
        let results = await trashManager.moveToTrash(items: [item1, item2]) { _, _ in }
        
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].status, .disappeared, "Item 1 should report as disappeared")
        XCTAssertEqual(results[1].status, .moved, "Item 2 should still be safely moved to Trash despite item 1 disappearing")
    }
    
    // MARK: - 4. Inaccessible Directory Handled Without Crashing
    func testInaccessibleDirectoryHandledWithoutCrashing() async {
        actor FailingScanner: CacheScanner {
            func scanCaches() async throws -> [ScanResultItem] {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
            }
        }
        
        let coordinator = DefaultScanCoordinator(cacheScanner: FailingScanner())
        let (summary, results, warnings) = await coordinator.performScan(usedSpace: 1000, threshold: .allLarge) { _ in }
        
        XCTAssertTrue(summary.isPartial, "Scan should be marked partial when a scanner encounters an error")
        XCTAssertTrue(results[.caches]?.isEmpty ?? true, "Caches should safely fallback to empty")
        XCTAssertFalse(warnings.isEmpty, "Warnings should capture the inaccessible location")
    }
    
    // MARK: - 5. Canonical Path Deduplication
    func testDeduplicationHandlesDuplicateCandidates() async {
        let path = URL(fileURLWithPath: "/Users/test/Library/Caches/duplicate.db")
        let item1 = ScanResultItem(name: "duplicate.db", path: path, size: 1024, category: .caches, status: .knownCache)
        let item2 = ScanResultItem(name: "duplicate.db", path: path, size: 1024, category: .caches, status: .knownCache)
        
        let coordinator = DefaultScanCoordinator()
        let input: [CleanupCategory: [ScanResultItem]] = [
            .caches: [item1, item2]
        ]
        
        let deduplicated = await coordinator.deduplicate(results: input)
        XCTAssertEqual(deduplicated[.caches]?.count, 1, "Duplicate canonical paths must be deduplicated")
    }
    
    // MARK: - 6. Static Code Invariant Audit: No rm, Process, or Permanent Deletion in App Code
    func testNoPermanentDeletionInProductionSources() throws {
        let srcURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("SweepMyMac")
        
        let enumerator = fileManager.enumerator(at: srcURL, includingPropertiesForKeys: nil)!
        var forbiddenOccurrences: [String] = []
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            
            if content.contains("Process(") {
                forbiddenOccurrences.append("\(fileURL.lastPathComponent): contains Process(")
            }
            if content.contains("FileManager.default.removeItem") {
                forbiddenOccurrences.append("\(fileURL.lastPathComponent): contains FileManager.default.removeItem")
            }
            if content.contains("/bin/rm") || content.contains("rm -rf") {
                forbiddenOccurrences.append("\(fileURL.lastPathComponent): contains rm command")
            }
        }
        
        XCTAssertTrue(forbiddenOccurrences.isEmpty, "Production source code must never contain permanent deletion commands: \(forbiddenOccurrences)")
    }
}
