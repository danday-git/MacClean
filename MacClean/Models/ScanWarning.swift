import Foundation

enum ScanWarning: Hashable, Sendable {
    case permissionDenied(location: String)
    case inaccessibleDirectory(location: String)
    case scanCancelled
    case unavailableLocation(location: String)
    
    var localizedDescription: String {
        switch self {
        case .permissionDenied(let location):
            return "Permission denied for location: \(location)"
        case .inaccessibleDirectory(let location):
            return "Inaccessible directory: \(location)"
        case .scanCancelled:
            return "Scan was cancelled by the user"
        case .unavailableLocation(let location):
            return "Location unavailable: \(location)"
        }
    }
}
