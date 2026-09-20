import Foundation

protocol DeveloperDataScanning: Sendable {
    func scanDeveloperData() async throws -> [ScanResultItem]
}

actor DefaultDeveloperDataScanner: DeveloperDataScanning {
    
    private let homeDirectory: URL
    private let registry: DeveloperDataRuleRegistering
    private let sizeCalculator: FileSizeCalculating
    
    init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        registry: DeveloperDataRuleRegistering = DeveloperDataRuleRegistry(),
        sizeCalculator: FileSizeCalculating = DefaultFileSizeCalculator()
    ) {
        self.homeDirectory = homeDirectory
        self.registry = registry
        self.sizeCalculator = sizeCalculator
    }
    
    func scanDeveloperData() async throws -> [ScanResultItem] {
        var items: [ScanResultItem] = []
        let fileManager = FileManager.default
        let rules = registry.allRules()
        
        for rule in rules {
            try Task.checkCancellation()
            
            for relPath in rule.relativePaths {
                let targetURL = homeDirectory.appendingPathComponent(relPath).standardizedFileURL
                
                // 1. Check path containment
                guard ProtectedPaths.isContained(child: targetURL, parent: homeDirectory) else {
                    continue
                }
                
                // 2. Check if file/directory exists
                guard fileManager.fileExists(atPath: targetURL.path) else {
                    continue
                }
                
                // 3. Symlink rejection: do not follow or scan symlinks
                var statBuf = stat()
                if lstat(targetURL.path, &statBuf) == 0 && (statBuf.st_mode & S_IFMT) == S_IFLNK {
                    continue
                }
                
                // 4. Custom verification check if rule provides one
                if let verify = rule.verificationCheck, !verify(targetURL) {
                    continue
                }
                
                // 5. Calculate size asynchronously
                let size = await sizeCalculator.size(of: targetURL)
                guard size > 0 else { continue }
                
                // 6. Map confidence & rule protection to ItemStatus
                let status: ItemStatus
                if rule.isProtected || rule.confidence == .low {
                    status = .protected
                } else {
                    status = .safeToDelete
                }
                
                let detailedExplanation = """
                \(rule.description)
                
                Regenerable: \(rule.isRegenerable ? "Yes" : "No")
                Possible Consequence: \(rule.consequence)
                Confidence: \(rule.confidence.rawValue)
                """
                
                let item = ScanResultItem(
                    name: rule.name,
                    path: targetURL,
                    size: size,
                    category: .developerData,
                    status: status,
                    ownerApplication: rule.name,
                    explanation: detailedExplanation,
                    developerType: rule.type,
                    confidence: rule.confidence,
                    isRegenerable: rule.isRegenerable
                )
                
                items.append(item)
                // Stop at first matching path for this rule
                break
            }
        }
        
        return items.sorted { $0.size > $1.size }
    }
}
