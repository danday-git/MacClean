import XCTest
@testable import SweepMyMac

@MainActor
final class FilesystemIntegrationFixtureTests: XCTestCase {
    
    var fixtureRoot: URL!
    var simulatedHome: URL!
    var outsideTarget: URL!
    var safeCache: URL!
    var safeLeftover: URL!
    var symlinkToOutside: URL!
    
    let fileManager = FileManager.default
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let uniqueID = UUID().uuidString
        fixtureRoot = fileManager.temporaryDirectory.appendingPathComponent("SweepMyMacFixture_\(uniqueID)")
        simulatedHome = fixtureRoot.appendingPathComponent("UserHome")
        outsideTarget = fixtureRoot.appendingPathComponent("OutsideTarget")
        
        // Structure inside home
        safeCache = simulatedHome.appendingPathComponent("Library/Caches/com.fixture.safecache")
        safeLeftover = simulatedHome.appendingPathComponent("Library/Application Support/FixtureLeftover")
        symlinkToOutside = simulatedHome.appendingPathComponent("Library/Caches/SymlinkToOutside")
        
        // Create directories
        try fileManager.createDirectory(at: safeCache, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: safeLeftover, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: outsideTarget, withIntermediateDirectories: true)
        
        // Create dummy payload files
        try "cache data".write(to: safeCache.appendingPathComponent("data.bin"), atomically: true, encoding: .utf8)
        try "leftover data".write(to: safeLeftover.appendingPathComponent("prefs.json"), atomically: true, encoding: .utf8)
        try "sensitive outside data".write(to: outsideTarget.appendingPathComponent("secrets.txt"), atomically: true, encoding: .utf8)
        
        // Create Symlink pointing from inside home to outsideTarget
        try fileManager.createSymbolicLink(at: symlinkToOutside, withDestinationURL: outsideTarget)
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: fixtureRoot)
        try super.tearDownWithError()
    }
    
    func testFixtureValidationScenarios() throws {
        let validator = DefaultCleanupValidator(homeDirectory: simulatedHome)
        let selectionVM = CleanupSelectionViewModel()
        
        // 1. SafeCache Candidate
        let cacheItem = ScanResultItem(
            name: "SafeCache",
            path: safeCache,
            size: 100,
            category: .caches,
            status: .knownCache,
            explanation: "Legitimate user cache"
        )
        let cacheValidation = validator.validate(cacheItem)
        XCTAssertEqual(cacheValidation, .valid)
        selectionVM.toggle(cacheItem)
        XCTAssertTrue(selectionVM.isSelected(cacheItem), "SafeCache should be selectable")
        
        // 2. SafeLeftover Candidate
        let leftoverItem = ScanResultItem(
            name: "SafeLeftover",
            path: safeLeftover,
            size: 200,
            category: .appLeftovers,
            status: .knownLeftover,
            explanation: "Legitimate app leftover"
        )
        let leftoverValidation = validator.validate(leftoverItem)
        XCTAssertEqual(leftoverValidation, .valid)
        selectionVM.toggle(leftoverItem)
        XCTAssertTrue(selectionVM.isSelected(leftoverItem), "SafeLeftover should be selectable")
        
        // 3. SymlinkToOutside Candidate (Must be rejected)
        let symlinkItem = ScanResultItem(
            name: "SymlinkToOutside",
            path: symlinkToOutside,
            size: 50,
            category: .caches,
            status: .knownCache,
            explanation: "Symlink to outside folder"
        )
        let symlinkValidation = validator.validate(symlinkItem)
        XCTAssertEqual(symlinkValidation, .invalid(reason: .symbolicLinkDetected), "Symlink must be rejected immediately")
        
        // 4. OutsideTarget Candidate (Must be rejected)
        let outsideItem = ScanResultItem(
            name: "OutsideTarget",
            path: outsideTarget,
            size: 500,
            category: .caches,
            status: .knownCache,
            explanation: "Folder completely outside home"
        )
        let outsideValidation = validator.validate(outsideItem)
        XCTAssertEqual(outsideValidation, .invalid(reason: .pathOutsideHomeDirectory), "Path outside home must be rejected")
    }
}
