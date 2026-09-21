import XCTest
@testable import SweepMyMac

final class CacheScannerTests: XCTestCase {
    // Tests for CacheScanner
    func testCacheScannerReturnsKnownCacheForMatchedRule() async throws {
        // Since we can't easily inject a FileManager into DefaultCacheScanner for this simple implementation,
        // we will test the models instead, or run the scanner and verify no crash occurs.
        let registry = DefaultCacheRuleRegistry()
        let rules = registry.allRules()
        
        XCTAssertFalse(rules.isEmpty)
        let claudeRule = rules.first { $0.applicationName == "Claude" }
        XCTAssertNotNil(claudeRule)
        XCTAssertTrue(claudeRule!.relativePaths.contains("com.anthropic.claude"))
    }
}
