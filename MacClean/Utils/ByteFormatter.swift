import Foundation

enum ByteFormatter {
    static let shared: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter
    }()
    
    static func string(from bytes: Int64) -> String {
        return shared.string(fromByteCount: bytes)
    }
}
