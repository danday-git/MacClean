import XCTest
@testable import MacClean

final class CleanupValidatorTests: XCTestCase {
    
    func testValidatorRejectsProtectedPath() {
        let validator = DefaultCleanupValidator()
        let item = ScanResultItem(name: "System", path: URL(fileURLWithPath: "/System/Library"), size: 1000, category: .caches, status: .knownCache, explanation: "")
        
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .pathOutsideHomeDirectory)) // Fails home directory check first usually, or protected path depending on order
    }
    
    func testValidatorRejectsUnknownItem() {
        let validator = DefaultCleanupValidator()
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let item = ScanResultItem(name: "Unknown", path: homeDir.appendingPathComponent("Library/Caches/UnknownCache"), size: 1000, category: .caches, status: .unknown, explanation: "")
        
        // Create the file temporarily so fileExists check passes
        let path = item.path.path
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        defer { try? FileManager.default.removeItem(atPath: path) }
        
        let result = validator.validate(item)
        XCTAssertEqual(result, .invalid(reason: .unknownItem))
    }
    
    func testValidatorAllowsKnownCache() {
        let validator = DefaultCleanupValidator()
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let item = ScanResultItem(name: "Known", path: homeDir.appendingPathComponent("Library/Caches/com.test.cache"), size: 1000, category: .caches, status: .knownCache, explanation: "")
        
        // Create the file temporarily so fileExists check passes
        let path = item.path.path
        try? FileManager.default.createDirectory(atPath: homeDir.appendingPathComponent("Library/Caches").path, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        defer { try? FileManager.default.removeItem(atPath: path) }
        
        let result = validator.validate(item)
        XCTAssertEqual(result, .valid)
    }
}
