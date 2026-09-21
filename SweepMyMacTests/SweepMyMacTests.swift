import XCTest
@testable import SweepMyMac

final class SweepMyMacTests: XCTestCase {
    
    func testStorageSummaryFreeSpaceCalculation() {
        let summary = StorageSummary(totalSpace: 1000, usedSpace: 600, reclaimableSpace: 100)
        XCTAssertEqual(summary.freeSpace, 400)
    }
    
    func testMockScannerInitialization() async throws {
        let scanner = MockScanner()
        let summary = try await scanner.scanStorage()
        XCTAssertEqual(summary.totalSpace, 512_000_000_000)
    }
}
