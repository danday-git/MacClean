import Foundation

#if DEBUG
actor MockScanner: StorageScanner {
    func scanStorage() async throws -> StorageSummary {
        // Simulate delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return StorageSummary(
            totalSpace: 512_000_000_000,
            usedSpace: 412_000_000_000,
            reclaimableSpace: 18_700_000_000
        )
    }
    
    func scanCategory(_ category: CleanupCategory) async throws -> [ScanResultItem] {
        // Simulate delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        switch category {
        case .appLeftovers:
            return [
                ScanResultItem(name: "Claude", path: URL(fileURLWithPath: "~/Library/Application Support/Claude"), size: 7_800_000_000, category: .appLeftovers, status: .knownLeftover, explanation: "Application not installed but data remains."),
                ScanResultItem(name: "Slack", path: URL(fileURLWithPath: "~/Library/Application Support/Slack"), size: 1_200_000_000, category: .appLeftovers, status: .knownLeftover, explanation: "Application not installed but data remains."),
                ScanResultItem(
                    name: "com.tinyspeck.slackmacgap",
                    path: URL(fileURLWithPath: "/Users/demo/Library/Application Support/Slack"),
                    size: 200_000_000,
                    category: .appLeftovers,
                    status: .knownLeftover,
                    ownerApplication: "Slack",
                    explanation: "Slack is not currently installed, but SweepMyMac found application data associated with its known Bundle ID (com.tinyspeck.slackmacgap)."
                )
            ]
        case .caches:
            return [
                ScanResultItem(name: "Antigravity Cache", path: URL(fileURLWithPath: "~/Library/Caches/com.antigravity"), size: 374_000_000, category: .caches, status: .knownCache, explanation: "Safe to delete. Will be regenerated on next launch."),
                ScanResultItem(
                    name: "com.apple.Safari",
                    path: URL(fileURLWithPath: "/Users/demo/Library/Caches/com.apple.Safari"),
                    size: 800_000_000,
                    category: .caches,
                    status: .knownCache,
                    ownerApplication: nil,
                    explanation: "Safari browser cache."
                )
            ]
        case .developerData:
            return [
                ScanResultItem(name: "Android SDK", path: URL(fileURLWithPath: "~/Library/Android/sdk"), size: 33_000_000_000, category: .developerData, status: .possibleCandidate, explanation: "Large developer folder."),
                ScanResultItem(
                    name: "Xcode DerivedData",
                    path: URL(fileURLWithPath: "/Users/demo/Library/Developer/Xcode/DerivedData"),
                    size: 15_000_000_000,
                    category: .developerData,
                    status: .possibleCandidate,
                    ownerApplication: nil,
                    explanation: "Xcode generated data and logs."
                )
            ]
        case .largeFiles:
            return [
                ScanResultItem(name: "video.mov", path: URL(fileURLWithPath: "~/Downloads/video.mov"), size: 12_400_000_000, category: .largeFiles, status: .notJunk, explanation: "Large file found in Downloads.")
            ]
        }
    }
}
#endif
