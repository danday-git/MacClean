import Foundation

struct StorageBreakdown: Equatable, Sendable {
    let applicationsBytes: Int64
    let userFilesBytes: Int64
    let appDataBytes: Int64
    let cachesBytes: Int64
    let developerDataBytes: Int64
    let systemAndOtherBytes: Int64
    let totalUsedBytes: Int64
    
    init(
        applicationsBytes: Int64,
        userFilesBytes: Int64,
        appDataBytes: Int64,
        cachesBytes: Int64,
        developerDataBytes: Int64,
        systemAndOtherBytes: Int64,
        totalUsedBytes: Int64
    ) {
        self.applicationsBytes = applicationsBytes
        self.userFilesBytes = userFilesBytes
        self.appDataBytes = appDataBytes
        self.cachesBytes = cachesBytes
        self.developerDataBytes = developerDataBytes
        self.systemAndOtherBytes = systemAndOtherBytes
        self.totalUsedBytes = totalUsedBytes
    }
    
    var accountedForBytes: Int64 {
        applicationsBytes + userFilesBytes + appDataBytes + cachesBytes + developerDataBytes
    }
    
    func percentage(for bytes: Int64) -> Double {
        guard totalUsedBytes > 0 else { return 0 }
        return Double(bytes) / Double(totalUsedBytes)
    }
}
