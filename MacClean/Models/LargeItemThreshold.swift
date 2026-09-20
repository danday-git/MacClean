import Foundation

enum LargeItemThreshold: String, CaseIterable, Identifiable, Sendable {
    case large500MB = "500+ MB"
    case allLarge = "1+ GB"
    case veryLarge = "5+ GB"
    case huge = "10+ GB"
    
    var minimumBytes: Int64 {
        switch self {
        case .large500MB: return 524_288_000 // 500 MB
        case .allLarge: return 1_073_741_824 // 1 GB
        case .veryLarge: return 5_368_709_120 // 5 GB
        case .huge: return 10_737_418_240 // 10 GB
        }
    }
    
    var id: String { rawValue }
}
