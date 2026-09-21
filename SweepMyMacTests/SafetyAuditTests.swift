import XCTest
@testable import SweepMyMac

final class SafetyAuditTests: XCTestCase {
    
    var tempHome: URL!
    var validator: DefaultCleanupValidator!
    let fileManager = FileManager.default
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Create an isolated simulated home directory for testing
        let uniqueID = UUID().uuidString
        tempHome = fileManager.temporaryDirectory.appendingPathComponent("SweepMyMacTestHome_\(uniqueID)")
        try fileManager.createDirectory(at: tempHome, withIntermediateDirectories: true)
        
        validator = DefaultCleanupValidator(homeDirectory: tempHome)
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: tempHome)
        try super.tearDownWithError()
    }
    
    // MARK: - 1. Valid User File
    func testValidUserFile() throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches/com.test.app")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        let fileURL = cacheFolder.appendingPathComponent("cache.db")
        try "test-data".write(to: fileURL, atomically: true, encoding: .utf8)
        
        let item = ScanResultItem(name: "cache.db", path: fileURL, size: 9, category: .caches, status: .knownCache, explanation: "Test")
        let result = validator.validate(item)
        XCTAssertEqual(result, .valid)
    }
    
    // MARK: - 2. Valid User Directory
    func testValidUserDirectory() throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches/com.test.app")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let item = ScanResultItem(name: "com.test.app", path: cacheFolder, size: 100, category: .caches, status: .knownCache, explanation: "Test")
        let result = validator.validate(item)
        XCTAssertEqual(result, .valid)
    }
    
    // MARK: - 3. Protected System Paths
    func testProtectedSystemPaths() {
        let systemPaths = [
            "/System",
            "/System/Applications",
            "/Library",
            "/Applications",
            "/usr",
            "/bin",
            "/sbin",
            "/private",
            "/var"
        ]
        
        for path in systemPaths {
            let item = ScanResultItem(name: "Sys", path: URL(fileURLWithPath: path), size: 1000, category: .caches, status: .knownCache, explanation: "")
            let result = validator.validate(item)
            // Should be rejected either as outside home, protected path, or symlink (e.g. /var -> /private/var)
            XCTAssertTrue(
                result == .invalid(reason: .pathOutsideHomeDirectory) ||
                result == .invalid(reason: .protectedPath) ||
                result == .invalid(reason: .symbolicLinkDetected),
                "Path \(path) should be rejected"
            )
        }
    }
    
    // MARK: - 4. User Protected Directories
    func testUserProtectedDirectories() throws {
        let protectedDirs = [
            ".ssh",
            "Documents",
            "Desktop",
            "Library/Keychains"
        ]
        
        for rel in protectedDirs {
            let dirURL = tempHome.appendingPathComponent(rel)
            try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
            let item = ScanResultItem(name: rel, path: dirURL, size: 50, category: .caches, status: .knownCache, explanation: "")
            let result = validator.validate(item)
            XCTAssertEqual(result, .invalid(reason: .protectedPath), "Relative protected path \(rel) should be rejected as protected")
        }
    }
    
    // MARK: - 5. Outside Home Directory
    func testOutsideHomeDirectory() {
        let outsideURL = URL(fileURLWithPath: "/Library/Caches/SystemCache")
        let item = ScanResultItem(name: "Outside", path: outsideURL, size: 100, category: .caches, status: .knownCache, explanation: "")
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .pathOutsideHomeDirectory))
    }
    
    // MARK: - 6. Sibling Home Directory
    func testSiblingHomeDirectory() {
        // e.g. /Users/test vs /Users/test2
        let parentDir = tempHome.deletingLastPathComponent()
        let siblingHome = parentDir.appendingPathComponent(tempHome.lastPathComponent + "2")
        let siblingFile = siblingHome.appendingPathComponent("Library/Caches/App")
        
        let item = ScanResultItem(name: "Sibling", path: siblingFile, size: 100, category: .caches, status: .knownCache, explanation: "")
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .pathOutsideHomeDirectory))
    }
    
    // MARK: - 7. Symlink Inside Home (Must Reject)
    func testSymlinkInsideHome() throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let targetFile = cacheFolder.appendingPathComponent("realFile.txt")
        try "real".write(to: targetFile, atomically: true, encoding: .utf8)
        
        let linkURL = cacheFolder.appendingPathComponent("symlinkFile.txt")
        try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: targetFile)
        
        let item = ScanResultItem(name: "symlinkFile", path: linkURL, size: 4, category: .caches, status: .knownCache, explanation: "")
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .symbolicLinkDetected))
    }
    
    // MARK: - 8. Symlink Outside Home
    func testSymlinkOutsideHome() throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let linkURL = cacheFolder.appendingPathComponent("linkToSystem")
        try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: URL(fileURLWithPath: "/System"))
        
        let item = ScanResultItem(name: "linkToSystem", path: linkURL, size: 4, category: .caches, status: .knownCache, explanation: "")
        let result = validator.validate(item)
        // Must be rejected as symlink or outside home
        XCTAssertTrue(result == .invalid(reason: .symbolicLinkDetected) || result == .invalid(reason: .pathOutsideHomeDirectory))
    }
    
    // MARK: - 9. Broken Symlink
    func testBrokenSymlink() throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let linkURL = cacheFolder.appendingPathComponent("brokenLink")
        let nonExistentTarget = tempHome.appendingPathComponent("doesNotExist_\(UUID().uuidString)")
        try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: nonExistentTarget)
        
        let item = ScanResultItem(name: "brokenLink", path: linkURL, size: 0, category: .caches, status: .knownCache, explanation: "")
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .symbolicLinkDetected))
    }
    
    // MARK: - 10. Disappeared File
    func testDisappearedFile() {
        let missingURL = tempHome.appendingPathComponent("Library/Caches/missing_\(UUID().uuidString)")
        let item = ScanResultItem(name: "Missing", path: missingURL, size: 100, category: .caches, status: .knownCache, explanation: "")
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .itemDisappeared))
    }
    
    // MARK: - 11. Path Traversal
    func testPathTraversal() {
        let traversalURL = tempHome.appendingPathComponent("Library/Caches/../Documents/secret.txt")
        let item = ScanResultItem(name: "Traversal", path: traversalURL, size: 100, category: .caches, status: .knownCache, explanation: "")
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .pathTraversalDetected))
    }
    
    // MARK: - 12. Unknown Candidate
    func testUnknownCandidate() throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches/UnknownApp")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let item = ScanResultItem(name: "UnknownApp", path: cacheFolder, size: 100, category: .caches, status: .unknown, explanation: "")
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .unknownItem))
    }
    
    // MARK: - 13. Protected Status Candidate
    func testProtectedStatusCandidate() throws {
        let cacheFolder = tempHome.appendingPathComponent("Library/Caches/ProtectedApp")
        try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        
        let item = ScanResultItem(name: "ProtectedApp", path: cacheFolder, size: 100, category: .caches, status: .protected, explanation: "")
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .unknownItem))
    }
}
