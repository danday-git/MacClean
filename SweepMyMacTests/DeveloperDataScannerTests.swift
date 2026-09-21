import XCTest
@testable import SweepMyMac

final class DeveloperDataScannerTests: XCTestCase {
    
    var fixtureHome: URL!
    let fileManager = FileManager.default
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let uniqueID = UUID().uuidString
        fixtureHome = fileManager.temporaryDirectory.appendingPathComponent("DevFixture_\(uniqueID)")
        try fileManager.createDirectory(at: fixtureHome, withIntermediateDirectories: true)
        
        // Setup mock ecosystem data inside fixtureHome
        
        // 1. npm
        let npmCache = fixtureHome.appendingPathComponent(".npm/_cacache")
        try fileManager.createDirectory(at: npmCache, withIntermediateDirectories: true)
        try "npm content".write(to: npmCache.appendingPathComponent("index.json"), atomically: true, encoding: .utf8)
        
        // 2. gradle
        let gradleCaches = fixtureHome.appendingPathComponent(".gradle/caches")
        try fileManager.createDirectory(at: gradleCaches, withIntermediateDirectories: true)
        try "gradle jars".write(to: gradleCaches.appendingPathComponent("jars-1.bin"), atomically: true, encoding: .utf8)
        // config file that must NOT be scanned:
        let gradleProps = fixtureHome.appendingPathComponent(".gradle/gradle.properties")
        try "org.gradle.jvmargs=-Xmx2048m".write(to: gradleProps, atomically: true, encoding: .utf8)
        
        // 3. maven
        let mavenRepo = fixtureHome.appendingPathComponent(".m2/repository/com/example")
        try fileManager.createDirectory(at: mavenRepo, withIntermediateDirectories: true)
        try "jar bytes".write(to: mavenRepo.appendingPathComponent("artifact.jar"), atomically: true, encoding: .utf8)
        // config file that must NOT be scanned:
        let mavenSettings = fixtureHome.appendingPathComponent(".m2/settings.xml")
        try "<settings/>".write(to: mavenSettings, atomically: true, encoding: .utf8)
        
        // 4. xcode
        let derivedData = fixtureHome.appendingPathComponent("Library/Developer/Xcode/DerivedData/App-abc")
        try fileManager.createDirectory(at: derivedData, withIntermediateDirectories: true)
        try "build objects".write(to: derivedData.appendingPathComponent("app.o"), atomically: true, encoding: .utf8)
        
        let archives = fixtureHome.appendingPathComponent("Library/Developer/Xcode/Archives/2026-09-18")
        try fileManager.createDirectory(at: archives, withIntermediateDirectories: true)
        try "signed xcarchive".write(to: archives.appendingPathComponent("App.xcarchive"), atomically: true, encoding: .utf8)
        
        // 5. docker & colima
        let dockerContainer = fixtureHome.appendingPathComponent("Library/Containers/com.docker.docker/Data")
        try fileManager.createDirectory(at: dockerContainer, withIntermediateDirectories: true)
        try "docker disk".write(to: dockerContainer.appendingPathComponent("Docker.raw"), atomically: true, encoding: .utf8)
        
        let colimaDir = fixtureHome.appendingPathComponent(".colima/_disks")
        try fileManager.createDirectory(at: colimaDir, withIntermediateDirectories: true)
        try "colima disk".write(to: colimaDir.appendingPathComponent("diffdisk.qcow2"), atomically: true, encoding: .utf8)
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: fixtureHome)
        try super.tearDownWithError()
    }
    
    func testDeveloperDataScannerDetection() async throws {
        let scanner = DefaultDeveloperDataScanner(homeDirectory: fixtureHome)
        let items = try await scanner.scanDeveloperData()
        
        XCTAssertFalse(items.isEmpty, "Scanner should detect developer items")
        
        let itemTypes = Dictionary(grouping: items, by: { $0.developerType })
        
        // 1. npm Cache: detected, high confidence, safeToDelete
        guard let npmItem = itemTypes[.npmCache]?.first else {
            XCTFail("npm Cache should be detected")
            return
        }
        XCTAssertEqual(npmItem.confidence, .high)
        XCTAssertEqual(npmItem.status, .safeToDelete)
        XCTAssertTrue(npmItem.isRegenerable)
        
        // 2. Gradle Cache: detected, but gradle.properties NOT present as item
        guard let gradleItem = itemTypes[.gradleCache]?.first else {
            XCTFail("Gradle Cache should be detected")
            return
        }
        XCTAssertEqual(gradleItem.confidence, .high)
        XCTAssertEqual(gradleItem.status, .safeToDelete)
        XCTAssertFalse(items.contains(where: { $0.name.contains("gradle.properties") }))
        
        // 3. Maven: detected as medium confidence (manual review), settings.xml NOT present
        guard let mavenItem = itemTypes[.mavenRepository]?.first else {
            XCTFail("Maven repository should be detected")
            return
        }
        XCTAssertEqual(mavenItem.confidence, .medium)
        XCTAssertFalse(items.contains(where: { $0.name.contains("settings.xml") }))
        
        // 4. Xcode DerivedData: high confidence
        guard let ddItem = itemTypes[.xcodeDerivedData]?.first else {
            XCTFail("Xcode DerivedData should be detected")
            return
        }
        XCTAssertEqual(ddItem.confidence, .high)
        XCTAssertEqual(ddItem.status, .safeToDelete)
        
        // 5. Xcode Archives: low confidence, protected
        guard let archivesItem = itemTypes[.xcodeArchives]?.first else {
            XCTFail("Xcode Archives should be detected")
            return
        }
        XCTAssertEqual(archivesItem.confidence, .low)
        XCTAssertEqual(archivesItem.status, .protected)
        XCTAssertFalse(archivesItem.isRegenerable)
        
        // 6. Docker & Colima: low confidence, protected
        guard let dockerItem = itemTypes[.dockerCache]?.first else {
            XCTFail("Docker Data should be detected")
            return
        }
        XCTAssertEqual(dockerItem.confidence, .low)
        XCTAssertEqual(dockerItem.status, .protected)
        
        guard let colimaItem = itemTypes[.colimaData]?.first else {
            XCTFail("Colima Data should be detected")
            return
        }
        XCTAssertEqual(colimaItem.confidence, .low)
        XCTAssertEqual(colimaItem.status, .protected)
    }
}
