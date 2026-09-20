import Foundation

protocol StorageScanner: Sendable {
    func scanStorage() async throws -> StorageSummary
    func scanCategory(_ category: CleanupCategory) async throws -> [ScanResultItem]
}
