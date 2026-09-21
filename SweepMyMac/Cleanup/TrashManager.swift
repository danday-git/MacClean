import Foundation
import os.log

protocol TrashManaging: Sendable {
    func moveToTrash(items: [ScanResultItem], progress: @escaping @Sendable (Int, Int) -> Void) async -> [TrashOperationResult]
}

final class DefaultTrashManager: TrashManaging {
    private let validator: CleanupValidating
    private let logger = Logger(subsystem: "com.sweepmymac", category: "TrashManager")
    private let homeDirectory: URL
    
    init(
        validator: CleanupValidating = DefaultCleanupValidator(),
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.validator = validator
        self.homeDirectory = homeDirectory
    }
    
    func moveToTrash(items: [ScanResultItem], progress: @escaping @Sendable (Int, Int) -> Void) async -> [TrashOperationResult] {
        var results: [TrashOperationResult] = []
        let total = items.count
        
        logger.info("SweepMyMac.cleanup.started - Batch size: \(total)")
        
        for (index, item) in items.enumerated() {
            let result = await moveToTrashSingle(item: item)
            results.append(result)
            progress(index + 1, total)
        }
        
        logger.info("SweepMyMac.cleanup.completed - Processed \(total) items")
        return results
    }
    
    private func moveToTrashSingle(item: ScanResultItem) async -> TrashOperationResult {
        // 1. Primary Revalidation via Validator
        let validation = validator.validate(item)
        
        switch validation {
        case .valid:
            break
        case .invalid(let reason):
            if reason == .itemDisappeared {
                logger.warning("SweepMyMac.cleanup.disappeared: Item was removed or changed prior to cleanup")
                return TrashOperationResult(sourceItem: item, status: .disappeared, error: nil)
            } else {
                logger.warning("SweepMyMac.cleanup.rejected - Reason: \(String(describing: reason), privacy: .public)")
                return TrashOperationResult(sourceItem: item, status: .rejected, error: nil)
            }
        }
        
        // 2. Defense-in-Depth Sanity Checks (TrashManager should not blindly trust outside state)
        let homeDir = self.homeDirectory
        let canonicalURL = item.path.standardizedFileURL.resolvingSymlinksInPath()
        
        // Re-check containment strictly
        if !ProtectedPaths.isContained(child: item.path, parent: homeDir) ||
           !ProtectedPaths.isContained(child: canonicalURL, parent: homeDir) {
            logger.error("SweepMyMac.cleanup.rejected - Defense-in-depth check failed: path outside home directory")
            return TrashOperationResult(sourceItem: item, status: .rejected, error: nil)
        }
        
        // Re-check protected paths
        if ProtectedPaths.isProtected(url: item.path, homeDirectory: homeDir) ||
           ProtectedPaths.isProtected(url: canonicalURL, homeDirectory: homeDir) {
            logger.error("SweepMyMac.cleanup.rejected - Defense-in-depth check failed: protected path")
            return TrashOperationResult(sourceItem: item, status: .rejected, error: nil)
        }
        
        // Re-check that item is not a symbolic link (lstat)
        var statBuf = stat()
        if lstat(item.path.path, &statBuf) != 0 || (statBuf.st_mode & S_IFMT) == S_IFLNK {
            logger.error("SweepMyMac.cleanup.rejected - Defense-in-depth check failed: item is symbolic link or inaccessible")
            return TrashOperationResult(sourceItem: item, status: .rejected, error: nil)
        }
        
        // 3. Final Validation Pass (Double-Validation Layer immediately before native Trash execution)
        let finalValidation = validator.validate(item)
        guard case .valid = finalValidation else {
            logger.error("SweepMyMac.cleanup.rejected - Final pre-trash validation failed: TOCTOU safety trigger")
            return TrashOperationResult(sourceItem: item, status: .rejected, error: nil)
        }
        
        // 4. Execute Native Trash Operation Immediately
        do {
            var resultingURL: NSURL?
            try FileManager.default.trashItem(at: item.path, resultingItemURL: &resultingURL)
            logger.info("SweepMyMac.cleanup.moved - Category: \(item.category.rawValue, privacy: .public)")
            return TrashOperationResult(sourceItem: item, status: .moved, error: nil)
        } catch {
            logger.error("SweepMyMac.cleanup.failed - Operation error encountered")
            return TrashOperationResult(sourceItem: item, status: .failed, error: error)
        }
    }
}
