import XCTest
@testable import MacClean

final class DeveloperDataRuleRegistryTests: XCTestCase {
    
    func testRegistryRulesAreValidAndSpecific() {
        let registry = DeveloperDataRuleRegistry()
        let rules = registry.allRules()
        
        XCTAssertFalse(rules.isEmpty, "Rule registry should not be empty")
        
        var seenIDs = Set<String>()
        for rule in rules {
            XCTAssertFalse(seenIDs.contains(rule.id), "Duplicate rule ID found: \(rule.id)")
            seenIDs.insert(rule.id)
            
            XCTAssertFalse(rule.name.isEmpty, "Rule name must not be empty")
            XCTAssertFalse(rule.relativePaths.isEmpty, "Rule must have at least one relative path")
            
            // Validate specificity: paths must not be broad or attempt traversal
            for path in rule.relativePaths {
                XCTAssertFalse(path.isEmpty, "Path must not be empty")
                XCTAssertFalse(path.hasPrefix("/"), "Relative path must not start with /")
                XCTAssertFalse(path.contains(".."), "Rule path must not contain traversal ..")
                XCTAssertNotEqual(path, "Library", "Rule must not target root Library")
                XCTAssertNotEqual(path, "Library/Application Support", "Rule must not target root Application Support")
                XCTAssertNotEqual(path, "Library/Caches", "Rule must not target root Caches")
            }
        }
    }
    
    func testExpectedConfidenceLevels() {
        let registry = DeveloperDataRuleRegistry()
        let rules = registry.allRules()
        let ruleMap = Dictionary(uniqueKeysWithValues: rules.map { ($0.id, $0) })
        
        // High confidence / eligible by default
        XCTAssertEqual(ruleMap["xcode.derivedData"]?.confidence, .high)
        XCTAssertTrue(ruleMap["xcode.derivedData"]?.isSelectableByDefault == true)
        
        XCTAssertEqual(ruleMap["npm.cache"]?.confidence, .high)
        XCTAssertTrue(ruleMap["npm.cache"]?.isSelectableByDefault == true)
        
        XCTAssertEqual(ruleMap["gradle.cache"]?.confidence, .high)
        XCTAssertTrue(ruleMap["gradle.cache"]?.isSelectableByDefault == true)
        
        // Medium confidence / review manually
        XCTAssertEqual(ruleMap["maven.repository"]?.confidence, .medium)
        XCTAssertFalse(ruleMap["maven.repository"]?.isSelectableByDefault == true)
        
        XCTAssertEqual(ruleMap["androidstudio.cache"]?.confidence, .medium)
        XCTAssertFalse(ruleMap["androidstudio.cache"]?.isSelectableByDefault == true)
        
        // Low confidence / protected / informational
        XCTAssertEqual(ruleMap["xcode.archives"]?.confidence, .low)
        XCTAssertTrue(ruleMap["xcode.archives"]?.isProtected == true)
        
        XCTAssertEqual(ruleMap["docker.data"]?.confidence, .low)
        XCTAssertTrue(ruleMap["docker.data"]?.isProtected == true)
        
        XCTAssertEqual(ruleMap["colima.data"]?.confidence, .low)
        XCTAssertTrue(ruleMap["colima.data"]?.isProtected == true)
    }
}
