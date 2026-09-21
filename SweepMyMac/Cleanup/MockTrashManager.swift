import Foundation

#if DEBUG
final class MockTrashManager: @unchecked Sendable, TrashManaging {
    var shouldFail: Bool = false
    var shouldDisappear: Bool = false
    
    func moveToTrash(items: [ScanResultItem], progress: @escaping @Sendable (Int, Int) -> Void) async -> [TrashOperationResult] {
        var results: [TrashOperationResult] = []
        let total = items.count
        
        for (index, item) in items.enumerated() {
            // Artificial delay to simulate file system operation
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec
            
            let status: TrashOperationStatus
            
            if shouldDisappear {
                status = .disappeared
            } else if shouldFail {
                status = .failed
            } else {
                // By default mock always returns moved
                status = .moved
            }
            
            let result = TrashOperationResult(sourceItem: item, status: status, error: nil)
            results.append(result)
            
            progress(index + 1, total)
        }
        
        return results
    }
}
#endif
