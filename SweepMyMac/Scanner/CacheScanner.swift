import Foundation

protocol CacheScanner: Sendable {
    func scanCaches() async throws -> [ScanResultItem]
}

actor DefaultCacheScanner: CacheScanner {
    
    private let registry: CacheRuleRegistering
    private let sizeCalculator: FileSizeCalculating
    
    init(registry: CacheRuleRegistering = DefaultCacheRuleRegistry(),
         sizeCalculator: FileSizeCalculating = DefaultFileSizeCalculator()) {
        self.registry = registry
        self.sizeCalculator = sizeCalculator
    }
    
    func scanCaches() async throws -> [ScanResultItem] {
        let fileManager = FileManager.default
        let cachesDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches")
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cachesDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        let rules = registry.allRules()
        var items: [ScanResultItem] = []
        
        for folderURL in contents {
            try Task.checkCancellation()
            let folderName = folderURL.lastPathComponent
            
            // Skip protected/system paths and symlinks
            let resValues = try? folderURL.resourceValues(forKeys: [.isSymbolicLinkKey])
            if resValues?.isSymbolicLink == true {
                continue
            }
            if ProtectedPaths.isProtected(url: folderURL) || folderName.lowercased().hasPrefix("com.apple.") {
                continue
            }
            
            // Check if matches known rules
            var matchedRule: CacheRule?
            for rule in rules {
                if rule.relativePaths.contains(where: { $0.caseInsensitiveCompare(folderName) == .orderedSame }) {
                    matchedRule = rule
                    break
                }
            }
            
            let size = await sizeCalculator.size(of: folderURL)
            if size > 1_000_000 { // Only consider > 1MB
                if let rule = matchedRule {
                    items.append(
                        ScanResultItem(
                            name: rule.applicationName,
                            path: folderURL,
                            size: size,
                            category: .caches,
                            status: .knownCache,
                            ownerApplication: rule.applicationName,
                            explanation: "This is application cache data and may be recreated by \(rule.applicationName)."
                        )
                    )
                } else {
                    items.append(
                        ScanResultItem(
                            name: folderName,
                            path: folderURL,
                            size: size,
                            category: .caches,
                            status: .unknown,
                            ownerApplication: nil,
                            explanation: "This item could not be confidently associated with a supported application."
                        )
                    )
                }
            }
        }
        
        return items.sorted { $0.size > $1.size }
    }
}
