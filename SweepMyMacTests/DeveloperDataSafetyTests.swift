import XCTest
@testable import SweepMyMac

@MainActor
final class DeveloperDataSafetyTests: XCTestCase {
    
    var fixtureHome: URL!
    let fileManager = FileManager.default
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let uniqueID = UUID().uuidString
        fixtureHome = fileManager.temporaryDirectory.appendingPathComponent("DevSafetyFixture_\(uniqueID)")
        try fileManager.createDirectory(at: fixtureHome, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: fixtureHome)
        try super.tearDownWithError()
    }
    
    func testDeveloperCacheValidatorBehavior() throws {
        let validator = DefaultCleanupValidator(homeDirectory: fixtureHome)
        
        // 1. Valid DerivedData
        let ddURL = fixtureHome.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        try fileManager.createDirectory(at: ddURL, withIntermediateDirectories: true)
        try "index".write(to: ddURL.appendingPathComponent("cache.db"), atomically: true, encoding: .utf8)
        
        let validItem = ScanResultItem(
            name: "DerivedData",
            path: ddURL,
            size: 100,
            category: .developerData,
            status: .safeToDelete,
            developerType: .xcodeDerivedData,
            confidence: .high
        )
        XCTAssertEqual(validator.validate(validItem), .valid)
        
        // 2. Protected Archives
        let archivesURL = fixtureHome.appendingPathComponent("Library/Developer/Xcode/Archives")
        try fileManager.createDirectory(at: archivesURL, withIntermediateDirectories: true)
        let protectedItem = ScanResultItem(
            name: "Archives",
            path: archivesURL,
            size: 500,
            category: .developerData,
            status: .protected,
            developerType: .xcodeArchives,
            confidence: .low
        )
        // Validator must reject .protected status
        XCTAssertEqual(validator.validate(protectedItem), .invalid(reason: .unknownItem))
        
        // 3. Symlink replaced cache (Must be rejected as symbolicLinkDetected)
        let npmDir = fixtureHome.appendingPathComponent(".npm")
        try fileManager.createDirectory(at: npmDir, withIntermediateDirectories: true)
        let symlinkCache = npmDir.appendingPathComponent("_cacache_symlink")
        let outsideTarget = fixtureHome.appendingPathComponent("outside")
        try fileManager.createDirectory(at: outsideTarget, withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(at: symlinkCache, withDestinationURL: outsideTarget)
        
        let symlinkItem = ScanResultItem(
            name: "npm",
            path: symlinkCache,
            size: 100,
            category: .developerData,
            status: .safeToDelete,
            developerType: .npmCache,
            confidence: .high
        )
        XCTAssertEqual(validator.validate(symlinkItem), .invalid(reason: .symbolicLinkDetected))
    }
    
    func testDeveloperDataSelectionPolicy() {
        let selectionVM = CleanupSelectionViewModel()
        
        let highItem = ScanResultItem(
            name: "DerivedData",
            path: fixtureHome.appendingPathComponent("dd"),
            size: 100,
            category: .developerData,
            status: .safeToDelete,
            developerType: .xcodeDerivedData,
            confidence: .high
        )
        
        let mediumItem = ScanResultItem(
            name: "Maven",
            path: fixtureHome.appendingPathComponent("m2"),
            size: 200,
            category: .developerData,
            status: .safeToDelete,
            developerType: .mavenRepository,
            confidence: .medium
        )
        
        let lowItem = ScanResultItem(
            name: "Docker",
            path: fixtureHome.appendingPathComponent("docker"),
            size: 300,
            category: .developerData,
            status: .protected,
            developerType: .dockerCache,
            confidence: .low
        )
        
        let allItems = [highItem, mediumItem, lowItem]
        
        // 1. selectAll must only select high confidence
        selectionVM.selectAll(in: allItems)
        XCTAssertTrue(selectionVM.isSelected(highItem), "High confidence item should be auto-selected")
        XCTAssertFalse(selectionVM.isSelected(mediumItem), "Medium confidence item should NOT be auto-selected")
        XCTAssertFalse(selectionVM.isSelected(lowItem), "Low confidence item should NOT be selected")
        
        // 2. toggle can manually select medium item after review
        selectionVM.toggle(mediumItem)
        XCTAssertTrue(selectionVM.isSelected(mediumItem), "User should be able to manually select medium confidence item")
        
        // 3. toggle CANNOT select low / protected item
        selectionVM.toggle(lowItem)
        XCTAssertFalse(selectionVM.isSelected(lowItem), "User must NOT be able to select low / protected item")
    }
}
