import XCTest
@testable import MacClean

final class ScanCoordinatorTests: XCTestCase {
    
    struct FailingCacheScanner: CacheScanner {
        func scanCaches() async throws -> [ScanResultItem] {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated cache scan failure"])
        }
    }
    
    struct MockDevScanner: DeveloperDataScanning {
        func scanDeveloperData() async throws -> [ScanResultItem] {
            return [
                ScanResultItem(
                    name: "MockDevItem",
                    path: URL(fileURLWithPath: "/tmp/mock_dev"),
                    size: 1500,
                    category: .developerData,
                    status: .knownCache,
                    confidence: .high
                )
            ]
        }
    }
    
    struct MockAppScanner: ApplicationScanner {
        func scanInstalledApplications() async throws -> [InstalledApplication] {
            return []
        }
    }
    
    struct MockLeftoverDetector: AppLeftoverDetecting {
        func detectLeftovers(installedApplications: [InstalledApplication]) async throws -> [ScanResultItem] {
            return []
        }
    }
    
    struct MockLargeItemScanner: LargeItemScanning {
        func scanLargeItems(threshold: LargeItemThreshold) async throws -> [ScanResultItem] {
            return []
        }
        func discoverStorageBreakdown(usedSpace: Int64) async -> (breakdown: StorageBreakdown, topConsumers: [TopSpaceConsumer]) {
            return (
                StorageBreakdown(
                    applicationsBytes: 10_000_000,
                    userFilesBytes: 20_000_000,
                    appDataBytes: 5_000_000,
                    cachesBytes: 2_000_000,
                    developerDataBytes: 3_000_000,
                    systemAndOtherBytes: 10_000_000,
                    totalUsedBytes: 50_000_000
                ),
                []
            )
        }
    }
    
    func testCoordinatorPartialScanOnScannerFailure() async {
        let coordinator = DefaultScanCoordinator(
            appScanner: MockAppScanner(),
            leftoverDetector: MockLeftoverDetector(),
            cacheScanner: FailingCacheScanner(),
            developerScanner: MockDevScanner(),
            largeItemScanner: MockLargeItemScanner()
        )
        
        var logs: [String] = []
        let (summary, results, warnings) = await coordinator.performScan { msg in
            logs.append(msg)
        }
        
        XCTAssertTrue(summary.isPartial, "Scan must be marked partial if any scanner fails")
        XCTAssertFalse(warnings.isEmpty, "Warnings must record failure")
        XCTAssertEqual(results[.developerData]?.count, 1, "Successful scanner results must be preserved despite other scanner failures")
        XCTAssertEqual(results[.caches]?.count, 0, "Failing scanner must return empty results")
        XCTAssertFalse(logs.isEmpty, "Progress messages must be emitted")
    }
}
