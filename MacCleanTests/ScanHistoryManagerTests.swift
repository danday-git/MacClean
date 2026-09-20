import XCTest
@testable import MacClean

final class ScanHistoryManagerTests: XCTestCase {
    
    var tempFileURL: URL!
    
    override func setUp() {
        super.setUp()
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ScanHistoryTest_\(UUID().uuidString).json")
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }
    
    func testSaveAndRetrieveScanHistory() async {
        let manager = ScanHistoryManager(historyFileURL: tempFileURL)
        
        let entry1 = ScanHistoryEntry(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-100),
            duration: 2.5,
            bytesDetected: 5_000_000,
            eligibleBytes: 4_000_000,
            itemCount: 15,
            scannerWarningsCount: 0
        )
        
        let entry2 = ScanHistoryEntry(
            id: UUID(),
            timestamp: Date(),
            duration: 1.8,
            bytesDetected: 8_000_000,
            eligibleBytes: 7_500_000,
            itemCount: 22,
            scannerWarningsCount: 1
        )
        
        await manager.saveEntry(entry1)
        await manager.saveEntry(entry2)
        
        let entries = await manager.loadEntries()
        XCTAssertEqual(entries.count, 2)
        
        let last = await manager.lastEntry()
        XCTAssertEqual(last?.id, entry2.id, "Last entry must be the most recent entry")
        XCTAssertEqual(last?.itemCount, 22)
    }
}
