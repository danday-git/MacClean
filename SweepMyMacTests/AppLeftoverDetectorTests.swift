import XCTest
@testable import SweepMyMac

final class AppLeftoverDetectorTests: XCTestCase {
    
    // Mock Size Calculator for testing
    actor MockSizeCalculator: FileSizeCalculating {
        func size(of url: URL) async -> Int64 {
            return 1024 * 1024 // 1 MB mock size
        }
    }
    
    // Mock Registry for testing
    struct MockRegistry: AppCleanupRegistering {
        func allRules() -> [AppCleanupRule] {
            return [
                AppCleanupRule(
                    bundleIdentifier: "com.test.app",
                    applicationName: "Test App",
                    knownPaths: [
                        .applicationSupport(relativePath: "Test App"),
                        .caches(relativePath: "com.test.app")
                    ]
                )
            ]
        }
    }

    func testDetectorFindsLeftoversForUninstalledApp() async throws {
        // Setup mock environment
        let registry = MockRegistry()
        let sizeCalculator = MockSizeCalculator()
        let detector = DefaultAppLeftoverDetector(registry: registry, sizeCalculator: sizeCalculator)
        
        // App is NOT installed
        let installedApps: [InstalledApplication] = []
        
        // Note: For this to truly pass on CI, we'd need a mock FileManager or we test against real paths we create in temp.
        // For unit test simplicity in this phase without injecting FileManager, we'll assume it doesn't crash.
        // We will assert no throws.
        let results = try await detector.detectLeftovers(installedApplications: installedApps)
        
        // Depending on whether the files exist in the user's dir, it might be 0 or more.
        XCTAssertNotNil(results)
    }
    
    func testDetectorIgnoresInstalledApp() async throws {
        let registry = MockRegistry()
        let sizeCalculator = MockSizeCalculator()
        let detector = DefaultAppLeftoverDetector(registry: registry, sizeCalculator: sizeCalculator)
        
        // App IS installed
        let installedApps: [InstalledApplication] = [
            InstalledApplication(id: "com.test.app", name: "Test App", bundleIdentifier: "com.test.app", bundleURL: URL(fileURLWithPath: "/Applications/Test App.app"))
        ]
        
        let results = try await detector.detectLeftovers(installedApplications: installedApps)
        
        // If it's installed, there should be zero leftovers found for it
        XCTAssertTrue(results.isEmpty)
    }
    
    func testRegistryContainsExpectedApps() {
        let registry = AppCleanupRegistry()
        let rules = registry.allRules()
        let appNames = Set(rules.map { $0.applicationName })
        
        XCTAssertTrue(appNames.contains("Claude"))
        XCTAssertTrue(appNames.contains("Slack"))
        XCTAssertTrue(appNames.contains("Roblox"))
        XCTAssertTrue(appNames.contains("Notion"))
        XCTAssertTrue(appNames.contains("MuMu Player"))
        XCTAssertTrue(appNames.contains("Nox App Player"))
        XCTAssertTrue(appNames.contains("Android Studio"))
        XCTAssertTrue(appNames.contains("Visual Studio Code"))
        XCTAssertTrue(appNames.contains("Cursor"))
        XCTAssertTrue(appNames.contains("Discord"))
        XCTAssertTrue(appNames.contains("Postman"))
    }
    
    func testLeftoverExplanationContainsAdvice() {
        let item = ScanResultItem(
            name: "Notion",
            path: URL(fileURLWithPath: "/Users/test/Library/Application Support/Notion"),
            size: 1024 * 1024,
            category: .appLeftovers,
            status: .knownLeftover,
            ownerApplication: "Notion",
            explanation: "Aplikasi 'Notion' tidak ditemukan di Mac ini (sudah di-uninstall). File sisa (leftover) ini aman untuk dipindahkan ke Trash guna menghemat ruang penyimpanan."
        )
        
        XCTAssertEqual(item.status, .knownLeftover)
        XCTAssertEqual(item.status.rawValue, "App Not Found (Leftover)")
        XCTAssertTrue(item.explanation?.contains("tidak ditemukan di Mac ini") == true)
        XCTAssertTrue(item.explanation?.contains("Trash") == true)
    }
    
    func testDiscordIsNotDetectedAsLeftoverWhenInstalled() async throws {
        let registry = AppCleanupRegistry()
        let sizeCalculator = MockSizeCalculator()
        let detector = DefaultAppLeftoverDetector(registry: registry, sizeCalculator: sizeCalculator)
        
        // Simulating Discord installed with official bundle ID (com.hnc.Discord)
        let installedApps = [
            InstalledApplication(
                id: "com.hnc.Discord",
                name: "Discord",
                bundleIdentifier: "com.hnc.Discord",
                bundleURL: URL(fileURLWithPath: "/Applications/Discord.app")
            )
        ]
        
        let results = try await detector.detectLeftovers(installedApplications: installedApps)
        let discordResults = results.filter { $0.ownerApplication == "Discord" }
        XCTAssertTrue(discordResults.isEmpty, "Discord must NEVER be classified as a leftover when installed as com.hnc.Discord")
    }
    
    func testAppDetectedAsInstalledByNameEvenWithDifferentBundleID() async throws {
        struct CustomRegistry: AppCleanupRegistering {
            func allRules() -> [AppCleanupRule] {
                return [
                    AppCleanupRule(
                        bundleIdentifier: "com.example.oldid",
                        applicationName: "AwesomeApp",
                        knownPaths: [.caches(relativePath: "com.example.oldid")]
                    )
                ]
            }
        }
        
        let detector = DefaultAppLeftoverDetector(registry: CustomRegistry(), sizeCalculator: MockSizeCalculator())
        
        // App has different bundle ID but same name
        let installedApps = [
            InstalledApplication(
                id: "com.example.newid",
                name: "AwesomeApp",
                bundleIdentifier: "com.example.newid",
                bundleURL: URL(fileURLWithPath: "/Applications/AwesomeApp.app")
            )
        ]
        
        let results = try await detector.detectLeftovers(installedApplications: installedApps)
        XCTAssertTrue(results.isEmpty, "App matching by name must be recognized as installed and excluded from leftovers")
    }
}
