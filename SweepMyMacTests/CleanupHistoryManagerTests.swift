import XCTest
@testable import SweepMyMac

final class CleanupHistoryManagerTests: XCTestCase {
    
    func testSaveAndLoadHistory() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("History.json")
        try? FileManager.default.createDirectory(at: tempURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent()) }
        
        let manager = CleanupHistoryManager(historyFileURL: tempURL)
        
        let entry1 = CleanupHistoryEntry(id: UUID(), date: Date(), itemCount: 5, totalBytesMoved: 1024)
        await manager.saveEntry(entry1)
        
        let entries = await manager.loadEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.totalBytesMoved, 1024)
        
        let last = await manager.lastEntry()
        XCTAssertEqual(last?.itemCount, 5)
    }
}
