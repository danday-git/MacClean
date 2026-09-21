import Foundation

struct StorageSummary: Equatable {
    var totalSpace: Int64
    var usedSpace: Int64
    var reclaimableSpace: Int64
    
    var freeSpace: Int64 {
        return totalSpace - usedSpace
    }
}
