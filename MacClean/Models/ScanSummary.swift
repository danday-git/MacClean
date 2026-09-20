import Foundation

struct ScanSummary: Equatable, Sendable {
    let totalScannedBytes: Int64
    let reclaimableBytes: Int64
    let selectedBytes: Int64
    let categorySummaries: [CategorySummary]
    let scanDuration: TimeInterval
    let warnings: [ScanWarning]
    let isPartial: Bool
    let storageBreakdown: StorageBreakdown?
    let topConsumers: [TopSpaceConsumer]
    
    init(
        totalScannedBytes: Int64,
        reclaimableBytes: Int64,
        selectedBytes: Int64 = 0,
        categorySummaries: [CategorySummary] = [],
        scanDuration: TimeInterval = 0,
        warnings: [ScanWarning] = [],
        isPartial: Bool = false,
        storageBreakdown: StorageBreakdown? = nil,
        topConsumers: [TopSpaceConsumer] = []
    ) {
        self.totalScannedBytes = totalScannedBytes
        self.reclaimableBytes = reclaimableBytes
        self.selectedBytes = selectedBytes
        self.categorySummaries = categorySummaries
        self.scanDuration = scanDuration
        self.warnings = warnings
        self.isPartial = isPartial
        self.storageBreakdown = storageBreakdown
        self.topConsumers = topConsumers
    }
}
