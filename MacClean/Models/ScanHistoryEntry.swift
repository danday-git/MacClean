import Foundation

struct ScanHistoryEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let duration: TimeInterval
    let bytesDetected: Int64
    let eligibleBytes: Int64
    let itemCount: Int
    let scannerWarningsCount: Int
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        duration: TimeInterval,
        bytesDetected: Int64,
        eligibleBytes: Int64,
        itemCount: Int,
        scannerWarningsCount: Int = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.duration = duration
        self.bytesDetected = bytesDetected
        self.eligibleBytes = eligibleBytes
        self.itemCount = itemCount
        self.scannerWarningsCount = scannerWarningsCount
    }
}
