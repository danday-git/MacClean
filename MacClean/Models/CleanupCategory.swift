import Foundation

enum CleanupCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case appLeftovers = "App Leftovers"
    case caches = "Caches"
    case developerData = "Developer Data"
    case largeFiles = "Large Files"
    
    var id: String { self.rawValue }
    
    func displayName(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.appLeftovers, .indonesian): return "Sisa Aplikasi"
        case (.appLeftovers, .english): return "App Leftovers"
        case (.caches, .indonesian): return "Cache Sistem"
        case (.caches, .english): return "System Caches"
        case (.developerData, .indonesian): return "Data Pengembang"
        case (.developerData, .english): return "Developer Data"
        case (.largeFiles, .indonesian): return "Berkas & Arsip Besar"
        case (.largeFiles, .english): return "Large Files"
        }
    }
}

