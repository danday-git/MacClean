import XCTest
@testable import MacClean

@MainActor
final class PerformanceTests: XCTestCase {
    
    func testSortingAndFilteringPerformance1000Items() {
        let viewModel = DashboardViewModel()
        
        var generatedItems: [ScanResultItem] = []
        generatedItems.reserveCapacity(1_000)
        
        for i in 0..<1_000 {
            generatedItems.append(
                ScanResultItem(
                    name: "Candidate_\(i)",
                    path: URL(fileURLWithPath: "/tmp/path_\(i)"),
                    size: Int64(i * 1024),
                    category: .caches,
                    status: i % 3 == 0 ? .knownCache : (i % 3 == 1 ? .protected : .safeToDelete),
                    confidence: i % 2 == 0 ? .high : .medium
                )
            )
        }
        
        viewModel.categoryItems = [.caches: generatedItems]
        
        let start = CFAbsoluteTimeGetCurrent()
        viewModel.selectedSort = .largestFirst
        viewModel.selectedFilter = .eligible
        let filtered = viewModel.filteredAndSortedItems(for: .caches)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        
        XCTAssertFalse(filtered.isEmpty)
        XCTAssertLessThan(elapsed, 0.05, "1,000 items sorting & filtering must complete in under 50ms (took \(elapsed * 1000)ms)")
    }
    
    func testSortingAndFilteringPerformance10000Items() {
        let viewModel = DashboardViewModel()
        
        var generatedItems: [ScanResultItem] = []
        generatedItems.reserveCapacity(10_000)
        
        for i in 0..<10_000 {
            generatedItems.append(
                ScanResultItem(
                    name: "Candidate_\(i)",
                    path: URL(fileURLWithPath: "/tmp/path_\(i)"),
                    size: Int64(i * 512),
                    category: .developerData,
                    status: i % 4 == 0 ? .protected : .knownCache,
                    confidence: i % 3 == 0 ? .high : (i % 3 == 1 ? .medium : .low)
                )
            )
        }
        
        viewModel.categoryItems = [.developerData: generatedItems]
        
        let start = CFAbsoluteTimeGetCurrent()
        viewModel.selectedSort = .largestFirst
        viewModel.selectedFilter = .eligible
        let filtered = viewModel.filteredAndSortedItems(for: .developerData)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        
        XCTAssertFalse(filtered.isEmpty)
        XCTAssertLessThan(elapsed, 0.20, "10,000 items sorting & filtering must complete in under 200ms (took \(elapsed * 1000)ms)")
    }
}
