import XCTest
@testable import MacClean

@MainActor
final class FilteringTests: XCTestCase {
    
    var viewModel: DashboardViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = DashboardViewModel()
        
        let leftover = ScanResultItem(
            name: "NotionLeftover",
            path: URL(fileURLWithPath: "/tmp/notion"),
            size: 500,
            category: .appLeftovers,
            status: .knownLeftover,
            ownerApplication: "Notion",
            confidence: .high
        )
        
        let cache = ScanResultItem(
            name: "ChromeCache",
            path: URL(fileURLWithPath: "/tmp/chrome"),
            size: 800,
            category: .caches,
            status: .knownCache,
            ownerApplication: "Google Chrome",
            confidence: .high
        )
        
        let devReview = ScanResultItem(
            name: "MavenRepo",
            path: URL(fileURLWithPath: "/tmp/maven"),
            size: 1200,
            category: .developerData,
            status: .knownCache,
            confidence: .medium
        )
        
        let devProtected = ScanResultItem(
            name: "XcodeArchives",
            path: URL(fileURLWithPath: "/tmp/archives"),
            size: 2000,
            category: .developerData,
            status: .protected,
            developerType: .xcodeArchives,
            confidence: .low
        )
        
        viewModel.categoryItems = [
            .appLeftovers: [leftover],
            .caches: [cache],
            .developerData: [devReview, devProtected]
        ]
    }
    
    func testFilterAll() {
        viewModel.selectedFilter = .all
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .appLeftovers).count, 1)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .caches).count, 1)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .developerData).count, 2)
    }
    
    func testFilterEligible() {
        viewModel.selectedFilter = .eligible
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .appLeftovers).count, 1)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .caches).count, 1)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .developerData).count, 1, "Only medium Maven repo is eligible; XcodeArchives is protected")
    }
    
    func testFilterReview() {
        viewModel.selectedFilter = .review
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .appLeftovers).count, 0)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .caches).count, 0)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .developerData).count, 1)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .developerData).first?.name, "MavenRepo")
    }
    
    func testFilterProtected() {
        viewModel.selectedFilter = .protected
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .appLeftovers).count, 0)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .caches).count, 0)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .developerData).count, 1)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .developerData).first?.name, "XcodeArchives")
    }
    
    func testSearchQueryMatching() {
        viewModel.selectedFilter = .all
        viewModel.searchText = "chrome"
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .caches).count, 1)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .appLeftovers).count, 0)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .developerData).count, 0)
        
        viewModel.searchText = "Notion"
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .appLeftovers).count, 1)
        XCTAssertEqual(viewModel.filteredAndSortedItems(for: .caches).count, 0)
    }
}
