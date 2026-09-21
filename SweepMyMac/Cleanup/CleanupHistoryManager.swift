import Foundation

struct CleanupHistoryEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let itemCount: Int
    let totalBytesMoved: Int64
}

actor CleanupHistoryManager {
    private let historyFileURL: URL
    
    init() {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sweepMyMacSupportURL = appSupportURL.appendingPathComponent("SweepMyMac")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: sweepMyMacSupportURL, withIntermediateDirectories: true)
        self.historyFileURL = sweepMyMacSupportURL.appendingPathComponent("CleanupHistory.json")
    }
    
    // For unit testing
    init(historyFileURL: URL) {
        self.historyFileURL = historyFileURL
    }
    
    func saveEntry(_ entry: CleanupHistoryEntry) {
        var entries = loadEntries()
        entries.append(entry)
        
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: historyFileURL, options: .atomic)
        }
    }
    
    func loadEntries() -> [CleanupHistoryEntry] {
        guard let data = try? Data(contentsOf: historyFileURL),
              let entries = try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data) else {
            return []
        }
        return entries
    }
    
    func lastEntry() -> CleanupHistoryEntry? {
        return loadEntries().sorted { $0.date > $1.date }.first
    }
}
