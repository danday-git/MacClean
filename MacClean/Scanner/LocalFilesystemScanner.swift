import Foundation

actor LocalFilesystemScanner: StorageScanner {
    
    func scanStorage() async throws -> StorageSummary {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        let values = try homeDir.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
        
        let totalSpace = Int64(values.volumeTotalCapacity ?? 0)
        let availableSpace = Int64(values.volumeAvailableCapacity ?? 0)
        let usedSpace = max(0, totalSpace - availableSpace)
        
        return StorageSummary(totalSpace: totalSpace, usedSpace: usedSpace, reclaimableSpace: 0)
    }
    
    func scanCategory(_ category: CleanupCategory) async throws -> [ScanResultItem] {
        switch category {
        case .appLeftovers:
            return try await scanAppLeftovers()
        case .caches:
            return try await scanCaches()
        case .developerData:
            return try await scanDeveloperData()
        case .largeFiles:
            return try await scanLargeFiles()
        }
    }
    
    // MARK: - App Leftovers Scanner
    private func scanAppLeftovers() async throws -> [ScanResultItem] {
        let appScanner = DefaultApplicationScanner()
        let leftoverDetector = DefaultAppLeftoverDetector()
        
        let installedApps = try await appScanner.scanInstalledApplications()
        return try await leftoverDetector.detectLeftovers(installedApplications: installedApps)
    }
    
    // MARK: - Caches Scanner
    private func scanCaches() async throws -> [ScanResultItem] {
        let cacheScanner = DefaultCacheScanner()
        return try await cacheScanner.scanCaches()
    }
    
    // MARK: - Developer Data Scanner
    private func scanDeveloperData() async throws -> [ScanResultItem] {
        let scanner = DefaultDeveloperDataScanner()
        return try await scanner.scanDeveloperData()
    }
    

    
    private func scanDirectory(url: URL, category: CleanupCategory) async -> [ScanResultItem]? {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        var items: [ScanResultItem] = []
        for folderURL in contents {
            try? Task.checkCancellation()
            let folderName = folderURL.lastPathComponent
            if folderName.lowercased().hasPrefix("com.apple.") {
                continue
            }
            let size = computeDirectorySize(at: folderURL)
            if size > 10_000_000 {
                items.append(
                    ScanResultItem(
                        name: folderName,
                        path: folderURL,
                        size: size,
                        category: category,
                        status: .knownCache,
                        explanation: "Temporary application cache."
                    )
                )
            }
        }
        return items
    }
    
    // MARK: - Large Files Scanner
    private func scanLargeFiles() async throws -> [ScanResultItem] {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        var items: [ScanResultItem] = []
        
        let searchDirectories = [
            homeDir.appendingPathComponent("Downloads"),
            homeDir.appendingPathComponent("Movies"),
            homeDir.appendingPathComponent("Documents")
        ]
        
        for dir in searchDirectories {
            try Task.checkCancellation()
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for fileURL in contents {
                try Task.checkCancellation()
                do {
                    let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
                    if values.isSymbolicLink == true { continue }
                    if values.isRegularFile == true, let fileSize = values.fileSize {
                        let size = Int64(fileSize)
                        // Threshold: Files larger than 50MB
                        if size > 50_000_000 {
                            items.append(
                                ScanResultItem(
                                    name: fileURL.lastPathComponent,
                                    path: fileURL,
                                    size: size,
                                    category: .largeFiles,
                                    status: .notJunk,
                                    explanation: "Large user file. This is personal data, not junk."
                                )
                            )
                        }
                    }
                } catch {
                    continue
                }
            }
        }
        
        return items.sorted { $0.size > $1.size }
    }
    
    // MARK: - Helper Utilities
    private func getInstalledAppIdentifiers() -> Set<String> {
        let fileManager = FileManager.default
        var identifiers = Set<String>()
        
        let searchDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        
        for dir in searchDirs {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for appURL in contents where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent.lowercased()
                identifiers.insert(appName)
                
                // Read bundle identifier if available
                if let bundle = Bundle(url: appURL), let bundleID = bundle.bundleIdentifier?.lowercased() {
                    identifiers.insert(bundleID)
                    if let lastPart = bundleID.split(separator: ".").last {
                        identifiers.insert(String(lastPart))
                    }
                }
            }
        }
        return identifiers
    }
    
    private func computeDirectorySize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isRegularFileKey, .isSymbolicLinkKey],
            options: [.skipsPackageDescendants]
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        var fileCount = 0
        
        while let fileURL = enumerator.nextObject() as? URL {
            // Cap depth check to prevent infinite loop
            fileCount += 1
            if fileCount > 25000 { break }
            
            do {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
                if values.isSymbolicLink == true { continue }
                if values.isRegularFile == true {
                    let size = values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0
                    totalSize += Int64(size)
                }
            } catch {
                continue
            }
        }
        return totalSize
    }
}
