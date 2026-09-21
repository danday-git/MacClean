import Foundation

enum CleanupWarning: Equatable, Sendable {
    case protectedPath
    case unknownItem
    case pathOutsideHomeDirectory
    case itemDisappeared
    case permissionDenied
    case symbolicLinkDetected
    case pathTraversalDetected
    case notRegularFileOrDirectory
}

struct CleanupPlan: Sendable {
    let items: [ScanResultItem]
    let totalSize: Int64
    let warnings: [CleanupWarning]
}
