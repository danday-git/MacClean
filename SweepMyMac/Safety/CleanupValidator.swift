import Foundation

enum CleanupValidationResult: Equatable, Sendable {
    case valid
    case invalid(reason: CleanupWarning)
}

protocol CleanupValidating: Sendable {
    func validate(_ item: ScanResultItem) -> CleanupValidationResult
}

struct DefaultCleanupValidator: CleanupValidating {
    let homeDirectory: URL
    private var fileManager: FileManager { .default }
    
    init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.homeDirectory = homeDirectory
    }
    
    func validate(_ item: ScanResultItem) -> CleanupValidationResult {
        let path = item.path.path
        
        // 1. Path Traversal Check
        if item.path.pathComponents.contains("..") || path.contains("/../") || path.hasSuffix("/..") {
            return .invalid(reason: .pathTraversalDetected)
        }
        
        // 2. Symlink Detection (check via lstat before resolving paths)
        var statBuffer = stat()
        if lstat(path, &statBuffer) == 0 {
            if (statBuffer.st_mode & S_IFMT) == S_IFLNK {
                return .invalid(reason: .symbolicLinkDetected)
            }
        }
        
        // 3. Strict Containment Check (Must be inside home directory)
        if !ProtectedPaths.isContained(child: item.path, parent: homeDirectory) {
            return .invalid(reason: .pathOutsideHomeDirectory)
        }
        
        // 4. Existence Check
        guard fileManager.fileExists(atPath: path) else {
            return .invalid(reason: .itemDisappeared)
        }
        
        // 5. Canonical Path Containment & Protected Check (Resolving symlinks in ancestry)
        let canonicalURL = item.path.standardizedFileURL.resolvingSymlinksInPath()
        if !ProtectedPaths.isContained(child: canonicalURL, parent: homeDirectory) {
            return .invalid(reason: .pathOutsideHomeDirectory)
        }
        
        // 6. Protected Paths Check (System & User protected paths)
        if ProtectedPaths.isProtected(url: item.path, homeDirectory: homeDirectory) ||
           ProtectedPaths.isProtected(url: canonicalURL, homeDirectory: homeDirectory) {
            return .invalid(reason: .protectedPath)
        }
        
        // 7. File Type Check (must be regular file or directory)
        if let attrs = try? fileManager.attributesOfItem(atPath: path),
           let fileType = attrs[.type] as? FileAttributeType {
            if fileType == .typeSymbolicLink {
                return .invalid(reason: .symbolicLinkDetected)
            }
            if fileType != .typeRegular && fileType != .typeDirectory {
                return .invalid(reason: .notRegularFileOrDirectory)
            }
        }
        
        // 8. Allowed Status Check
        switch item.status {
        case .knownLeftover, .knownCache, .safeToDelete:
            return .valid
        case .unknown, .possibleCandidate, .protected, .notJunk:
            return .invalid(reason: .unknownItem)
        }
    }
}
