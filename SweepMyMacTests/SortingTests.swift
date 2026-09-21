import XCTest
@testable import SweepMyMac

@MainActor
final class SortingTests: XCTestCase {
    
    var viewModel: DashboardViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = DashboardViewModel()
        
        let small = ScanResultItem(
            name: "SmallFile",
            path: URL(fileURLWithPath: "/tmp/small"),
            size: 50_000, // 50 KB
            category: .caches,
            status: .knownCache,
            confidence: .low
        )
        
        let medium = ScanResultItem(
            name: "MediumFile",
            path: URL(fileURLWithPath: "/tmp/medium"),
            size: 900_000_000, // 900 MB
            category: .caches,
            status: .knownCache,
            confidence: .medium
        )
        
        let large = ScanResultItem(
            name: "LargeFile",
            path: URL(fileURLWithPath: "/tmp/large"),
            size: 1_200_000_000, // 1.2 GB
            category: .caches,
            status: .knownCache,
            confidence: .high
        )
        
        viewModel.categoryItems = [
            .caches: [small, large, medium]
        ]
    }
    
    func testLargestFirstRawByteSorting() {
        viewModel.selectedSort = .largestFirst
        let items = viewModel.filteredAndSortedItems(for: .caches)
        
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].size, 1_200_000_000, "Largest must be first (1.2 GB)")
        XCTAssertEqual(items[1].size, 900_000_000, "Second must be 900 MB")
        XCTAssertEqual(items[2].size, 50_000, "Third must be 50 KB")
    }
    
    func testSmallestFirstRawByteSorting() {
        viewModel.selectedSort = .smallestFirst
        let items = viewModel.filteredAndSortedItems(for: .caches)
        
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].size, 50_000)
        XCTAssertEqual(items[1].size, 900_000_000)
        XCTAssertEqual(items[2].size, 1_200_000_000)
    }
    
    func testNameSorting() {
        viewModel.selectedSort = .name
        let items = viewModel.filteredAndSortedItems(for: .caches)
        
        XCTAssertEqual(items[0].name, "LargeFile")
        XCTAssertEqual(items[1].name, "MediumFile")
        XCTAssertEqual(items[2].name, "SmallFile")
    }
    
    func testConfidenceSorting() {
        viewModel.selectedSort = .confidence
        let items = viewModel.filteredAndSortedItems(for: .caches)
        
        XCTAssertEqual(items[0].confidence, .high)
        XCTAssertEqual(items[1].confidence, .medium)
        XCTAssertEqual(items[2].confidence, .low)
    }
}
