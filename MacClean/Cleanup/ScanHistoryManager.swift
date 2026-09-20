import Foundation

actor ScanHistoryManager {
    private let historyFileURL: URL
    
    init() {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let macCleanSupportURL = appSupportURL.appendingPathComponent("MacClean")
        
        try? FileManager.default.createDirectory(at: macCleanSupportURL, withIntermediateDirectories: true)
        self.historyFileURL = macCleanSupportURL.appendingPathComponent("ScanHistory.json")
    }
    
    init(historyFileURL: URL) {
        self.historyFileURL = historyFileURL
    }
    
    func saveEntry(_ entry: ScanHistoryEntry) {
        var entries = loadEntries()
        entries.append(entry)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) {
            try? data.write(to: historyFileURL, options: .atomic)
        }
    }
    
    func loadEntries() -> [ScanHistoryEntry] {
        guard let data = try? Data(contentsOf: historyFileURL) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let entries = try? decoder.decode([ScanHistoryEntry].self, from: data) else {
            return []
        }
        return entries
    }
    
    func lastEntry() -> ScanHistoryEntry? {
        return loadEntries().sorted { $0.timestamp > $1.timestamp }.first
    }
}
