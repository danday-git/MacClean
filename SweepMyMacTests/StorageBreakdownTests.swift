import XCTest
@testable import SweepMyMac

final class StorageBreakdownTests: XCTestCase {
    
    func testStorageBreakdownMathAndPercentages() {
        let breakdown = StorageBreakdown(
            applicationsBytes: 40_000_000_000,
            userFilesBytes: 80_000_000_000,
            appDataBytes: 30_000_000_000,
            cachesBytes: 15_000_000_000,
            developerDataBytes: 15_000_000_000,
            systemAndOtherBytes: 20_000_000_000,
            totalUsedBytes: 200_000_000_000
        )
        
        XCTAssertEqual(breakdown.accountedForBytes, 180_000_000_000)
        XCTAssertEqual(breakdown.totalUsedBytes, 200_000_000_000)
        
        // Percentages
        XCTAssertEqual(breakdown.percentage(for: breakdown.applicationsBytes), 0.20, accuracy: 0.001)
        XCTAssertEqual(breakdown.percentage(for: breakdown.userFilesBytes), 0.40, accuracy: 0.001)
        XCTAssertEqual(breakdown.percentage(for: breakdown.appDataBytes), 0.15, accuracy: 0.001)
        XCTAssertEqual(breakdown.percentage(for: breakdown.cachesBytes), 0.075, accuracy: 0.001)
        XCTAssertEqual(breakdown.percentage(for: breakdown.systemAndOtherBytes), 0.10, accuracy: 0.001)
    }
    
    func testTopSpaceConsumerRankingAndSubItems() {
        let consumer1 = TopSpaceConsumer(
            name: "Android SDK",
            path: URL(fileURLWithPath: "/Users/test/.android"),
            size: 33_200_000_000,
            categoryDescription: "Developer Data",
            subItems: [
                TopSpaceConsumer(
                    name: "avd",
                    path: URL(fileURLWithPath: "/Users/test/.android/avd"),
                    size: 20_000_000_000,
                    categoryDescription: "Emulators"
                ),
                TopSpaceConsumer(
                    name: "system-images",
                    path: URL(fileURLWithPath: "/Users/test/.android/system-images"),
                    size: 13_200_000_000,
                    categoryDescription: "Images"
                )
            ]
        )
        
        let consumer2 = TopSpaceConsumer(
            name: "Docker",
            path: URL(fileURLWithPath: "/Users/test/Library/Containers/com.docker.docker"),
            size: 12_400_000_000,
            categoryDescription: "Runtime data"
        )
        
        let consumer3 = TopSpaceConsumer(
            name: "Screen Recordings",
            path: URL(fileURLWithPath: "/Users/test/Movies/Screen Recordings"),
            size: 8_200_000_000,
            categoryDescription: "Personal file"
        )
        
        let consumers = [consumer2, consumer1, consumer3]
        let ranked = consumers.sorted { $0.size > $1.size }
        
        XCTAssertEqual(ranked[0].name, "Android SDK")
        XCTAssertEqual(ranked[0].size, 33_200_000_000)
        XCTAssertEqual(ranked[0].subItems.count, 2)
        XCTAssertEqual(ranked[1].name, "Docker")
        XCTAssertEqual(ranked[2].name, "Screen Recordings")
    }
}
