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
        badgeLabel(for: .english)
    }
    
    func badgeLabel(for language: AppLanguage) -> String {
        switch self {
        case .safeToClean: return language == .indonesian ? "Aman dibersihkan" : "Safe to clean"
        case .needsReview: return language == .indonesian ? "Perlu ditinjau" : "Review manually"
        case .protected: return language == .indonesian ? "Dilindungi" : "Protected"
        }
    }
    
    var shortDescription: String {
        shortDescription(for: .english)
    }
    
    func shortDescription(for language: AppLanguage) -> String {
        let isID = language == .indonesian
        switch self {
        case .safeToClean:
            return isID ? "Cache yang dapat dibuat ulang atau data sisa aplikasi. Aman dipindahkan ke Tempat Sampah." : "Regenerable cache or uninstalled application data. Safe to move to Trash."
        case .needsReview:
            return isID ? "Cache paket, data runtime, atau berkas pribadi. Mungkin perlu diunduh ulang atau diverifikasi." : "Package cache, runtime data, or personal file. May need to be redownloaded or verified."
        case .protected:
            return isID ? "Build rilis, simbol debug, atau data integritas sistem. SweepMyMac menjaga data ini tetap terlindungi." : "Release build, debugging symbols, or system integrity data. SweepMyMac keeps this protected."
        }
    }
}
