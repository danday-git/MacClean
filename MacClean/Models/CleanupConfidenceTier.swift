import Foundation
import SwiftUI

enum CleanupConfidenceTier: String, CaseIterable, Identifiable, Codable, Sendable {
    case safeToClean = "Safe to Clean"
    case needsReview = "Review Needed"
    case protected = "Protected"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .safeToClean: return "checkmark.shield.fill"
        case .needsReview: return "hand.raised.fill"
        case .protected: return "lock.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .safeToClean: return .green
        case .needsReview: return .purple
        case .protected: return .secondary
        }
    }
    
    var badgeLabel: String {
        switch self {
        case .safeToClean: return "Safe to clean"
        case .needsReview: return "Review manually"
        case .protected: return "Protected"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .safeToClean:
            return "Regenerable cache or uninstalled application data. Safe to move to Trash."
        case .needsReview:
            return "Package cache, runtime data, or personal file. May need to be redownloaded or verified."
        case .protected:
            return "Release build, debugging symbols, or system integrity data. MacClean keeps this protected."
        }
    }
}
