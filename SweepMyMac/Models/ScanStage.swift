import Foundation

enum ScanStage: String, CaseIterable, Identifiable, Sendable {
    case applications = "Applications"
    case leftovers = "Application leftovers"
    case caches = "Caches"
    case developerData = "Developer data"
    case largeFiles = "Large files"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .applications: return "app.badge.fill"
        case .leftovers: return "trash.circle.fill"
        case .caches: return "bolt.shield.fill"
        case .developerData: return "hammer.circle.fill"
        case .largeFiles: return "doc.badge.gearshape.fill"
        }
    }
}

enum ScanStageStatus: Equatable, Sendable {
    case pending
    case inProgress
    case completed
    case skipped
    case failed
}
