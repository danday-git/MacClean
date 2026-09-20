import Foundation

protocol FileSizeCalculating: Sendable {
    func size(of url: URL) async -> Int64
}

actor DefaultFileSizeCalculator: FileSizeCalculating {
    
    func size(of url: URL) async -> Int64 {
        let fileManager = FileManager.default
        
        // Single file check first
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }
        
        if !isDirectory.boolValue {
            do {
                let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
                if values.isSymbolicLink == true { return 0 }
                return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
            } catch {
                return 0
            }
        }
        
        // Directory recursive calculation
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [.skipsPackageDescendants]
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        var fileCount = 0
        
        while let fileURL = enumerator.nextObject() as? URL {
            // Check for cancellation periodically
            if Task.isCancelled { return totalSize }
            
            // Safety cap to prevent runaway calculation on massive trees
            fileCount += 1
            if fileCount > 50000 { break }
            
            do {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
                if values.isSymbolicLink == true { continue }
                if values.isRegularFile == true {
                    let size = values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0
                    totalSize += Int64(size)
                }
            } catch {
                // Ignore inaccessible files and continue
                continue
            }
        }
        
        return totalSize
    }
}
