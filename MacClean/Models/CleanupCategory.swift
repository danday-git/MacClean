import Foundation

enum CleanupCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case appLeftovers = "App Leftovers"
    case caches = "Caches"
    case developerData = "Developer Data"
    case largeFiles = "Large Files"
    
    var id: String { self.rawValue }
}
