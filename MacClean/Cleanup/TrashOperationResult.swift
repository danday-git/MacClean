import Foundation

enum TrashOperationStatus: Sendable {
    case moved
    case failed
    case disappeared
    case rejected
}

struct TrashOperationResult: Sendable {
    let sourceItem: ScanResultItem
    let status: TrashOperationStatus
    let error: Error?
}
