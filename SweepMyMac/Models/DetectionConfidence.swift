import Foundation

enum DetectionConfidence: String, Codable, Hashable, Sendable, CaseIterable {
    case high = "High Confidence"
    case medium = "Review Manually"
    case low = "Informational Only"
    
    var iconName: String {
        switch self {
        case .high: return "checkmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "lock.shield.fill"
        }
    }
}
