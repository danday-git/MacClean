import XCTest
@testable import SweepMyMac

@MainActor
final class SelectionViewModelTests: XCTestCase {
    
    func testSelectionToggling() throws {
        let vm = CleanupSelectionViewModel()
        let item = ScanResultItem(name: "Test", path: URL(fileURLWithPath: "/tmp/test"), size: 1000, category: .caches, status: .knownCache, explanation: "")
        
        XCTAssertFalse(vm.isSelected(item))
        
        vm.toggle(item)
        XCTAssertTrue(vm.isSelected(item))
        XCTAssertEqual(vm.selectedSize(from: [item]), 1000)
        
        vm.toggle(item)
        XCTAssertFalse(vm.isSelected(item))
        XCTAssertEqual(vm.selectedSize(from: [item]), 0)
    }
    
    func testSelectAllAndClear() throws {
        let vm = CleanupSelectionViewModel()
        let item1 = ScanResultItem(name: "1", path: URL(fileURLWithPath: "/tmp/1"), size: 100, category: .caches, status: .knownCache, explanation: "")
        let item2 = ScanResultItem(name: "2", path: URL(fileURLWithPath: "/tmp/2"), size: 200, category: .caches, status: .knownCache, explanation: "")
        let unknown = ScanResultItem(name: "3", path: URL(fileURLWithPath: "/tmp/3"), size: 300, category: .caches, status: .unknown, explanation: "")
        
        let allItems = [item1, item2, unknown]
        
        vm.selectAll(in: allItems)
        
        // Unknown items should not be selectable by default selectAll
        XCTAssertTrue(vm.isSelected(item1))
        XCTAssertTrue(vm.isSelected(item2))
        XCTAssertFalse(vm.isSelected(unknown))
        
        XCTAssertEqual(vm.selectedSize(from: allItems), 300)
        
        vm.clearSelection()
        XCTAssertTrue(vm.selectedItems.isEmpty)
        XCTAssertEqual(vm.selectedSize(from: allItems), 0)
    }
    
    func testIsAllSelectedAndToggleSelectAll() throws {
        let vm = CleanupSelectionViewModel()
        let item1 = ScanResultItem(name: "1", path: URL(fileURLWithPath: "/tmp/1"), size: 100, category: .caches, status: .knownCache, explanation: "")
        let item2 = ScanResultItem(name: "2", path: URL(fileURLWithPath: "/tmp/2"), size: 200, category: .caches, status: .knownCache, explanation: "")
        let items = [item1, item2]
        
        XCTAssertFalse(vm.isAllSelected(in: items))
        
        vm.toggleSelectAll(in: items)
        XCTAssertTrue(vm.isAllSelected(in: items))
        XCTAssertTrue(vm.isSelected(item1))
        XCTAssertTrue(vm.isSelected(item2))
        
        vm.toggleSelectAll(in: items)
        XCTAssertFalse(vm.isAllSelected(in: items))
        XCTAssertFalse(vm.isSelected(item1))
        XCTAssertFalse(vm.isSelected(item2))
    }
    
    func testIsAllRecommendedSelected() throws {
        let vm = CleanupSelectionViewModel()
        let item1 = ScanResultItem(name: "1", path: URL(fileURLWithPath: "/tmp/1"), size: 100, category: .caches, status: .knownCache, explanation: "")
        let item2 = ScanResultItem(name: "2", path: URL(fileURLWithPath: "/tmp/2"), size: 200, category: .caches, status: .knownCache, explanation: "")
        let categoryItems: [CleanupCategory: [ScanResultItem]] = [.caches: [item1, item2]]
        
        XCTAssertFalse(vm.isAllRecommendedSelected(from: categoryItems))
        
        vm.selectRecommended(in: categoryItems)
        XCTAssertTrue(vm.isAllRecommendedSelected(from: categoryItems))
    }
}
