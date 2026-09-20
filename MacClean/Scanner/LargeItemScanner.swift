import Foundation

protocol LargeItemScanning: Sendable {
    func scanLargeItems(threshold: LargeItemThreshold) async throws -> [ScanResultItem]
    func discoverStorageBreakdown(usedSpace: Int64) async -> (breakdown: StorageBreakdown, topConsumers: [TopSpaceConsumer])
}

actor DefaultLargeItemScanner: LargeItemScanning {
    
    private let sizeCalculator: FileSizeCalculating
    private let fileManager = FileManager.default
    
    init(sizeCalculator: FileSizeCalculating = DefaultFileSizeCalculator()) {
        self.sizeCalculator = sizeCalculator
    }
    
    func scanLargeItems(threshold: LargeItemThreshold) async throws -> [ScanResultItem] {
        var items: [ScanResultItem] = []
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let minBytes = threshold.minimumBytes
        
        let candidateDirs = [
            homeDir.appendingPathComponent("Downloads"),
            homeDir.appendingPathComponent("Movies"),
            homeDir.appendingPathComponent("Documents"),
            homeDir.appendingPathComponent("Desktop"),
            homeDir.appendingPathComponent("Pictures"),
            homeDir.appendingPathComponent("Music")
        ]
        
        // 1. Scan user directories with bounded depth (up to 3 levels deep)
        for dir in candidateDirs {
            try Task.checkCancellation()
            let foundInDir = try await scanDirectoryForLargeFiles(
                at: dir,
                currentDepth: 1,
                maxDepth: 3,
                minBytes: minBytes,
                thresholdName: threshold.rawValue
            )
            items.append(contentsOf: foundInDir)
        }
        
        // 2. Discover large app data folders (Application Support & Containers)
        let appDataParentDirs = [
            homeDir.appendingPathComponent("Library/Application Support"),
            homeDir.appendingPathComponent("Library/Containers")
        ]
        
        for parentDir in appDataParentDirs {
            try Task.checkCancellation()
            
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: parentDir.path, isDirectory: &isDir), isDir.boolValue else {
                continue
            }
            
            guard let subdirs = try? fileManager.contentsOfDirectory(
                at: parentDir,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for subdir in subdirs.prefix(25) {
                try Task.checkCancellation()
                let values = try? subdir.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
                if values?.isSymbolicLink == true || values?.isDirectory != true { continue }
                
                let size = await fastDirectorySize(at: subdir, maxFiles: 250)
                if size >= minBytes {
                    let item = createLargeItem(
                        for: subdir,
                        size: size,
                        isDirectory: true,
                        thresholdName: threshold.rawValue
                    )
                    items.append(item)
                }
            }
        }
        
        return items.sorted { $0.size > $1.size }
    }
    
    private func scanDirectoryForLargeFiles(
        at url: URL,
        currentDepth: Int,
        maxDepth: Int,
        minBytes: Int64,
        thresholdName: String
    ) async throws -> [ScanResultItem] {
        guard currentDepth <= maxDepth else { return [] }
        try Task.checkCancellation()
        
        var found: [ScanResultItem] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .isPackageKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        for fileURL in contents {
            try Task.checkCancellation()
            
            let resValues = try? fileURL.resourceValues(forKeys: [
                .isSymbolicLinkKey,
                .isRegularFileKey,
                .isDirectoryKey,
                .fileSizeKey,
                .isPackageKey
            ])
            
            // Skip symlinks
            if resValues?.isSymbolicLink == true { continue }
            
            // Skip packages (.app, etc.) from deep scanning; treat package as a unit if huge
            if resValues?.isPackage == true {
                let size = await fastDirectorySize(at: fileURL, maxFiles: 100)
                if size >= minBytes {
                    found.append(createLargeItem(for: fileURL, size: size, isDirectory: true, thresholdName: thresholdName))
                }
                continue
            }
            
            if resValues?.isRegularFile == true, let fileSize = resValues?.fileSize {
                let size = Int64(fileSize)
                if size >= minBytes {
                    found.append(createLargeItem(for: fileURL, size: size, isDirectory: false, thresholdName: thresholdName))
                }
            } else if resValues?.isDirectory == true {
                let folderName = fileURL.lastPathComponent
                if folderName == "node_modules" || folderName == ".git" || folderName == "Caches" || folderName == ".Trash" {
                    continue
                }
                
                // Recurse into subdirectories if depth allows
                if currentDepth < maxDepth {
                    let subItems = try await scanDirectoryForLargeFiles(
                        at: fileURL,
                        currentDepth: currentDepth + 1,
                        maxDepth: maxDepth,
                        minBytes: minBytes,
                        thresholdName: thresholdName
                    )
                    found.append(contentsOf: subItems)
                }
                
                // If top-level user folder itself is huge and none of its sub-items were already added
                if currentDepth == 1 {
                    let folderSize = await fastDirectorySize(at: fileURL, maxFiles: 200)
                    if folderSize >= minBytes {
                        let subPaths = Set(found.map { $0.path.path })
                        let hasSubFile = subPaths.contains { $0.hasPrefix(fileURL.path) }
                        if !hasSubFile {
                            found.append(createLargeItem(for: fileURL, size: folderSize, isDirectory: true, thresholdName: thresholdName))
                        }
                    }
                }
            }
        }
        
        return found
    }
    
    private func createLargeItem(
        for url: URL,
        size: Int64,
        isDirectory: Bool,
        thresholdName: String
    ) -> ScanResultItem {
        let ext = url.pathExtension.lowercased()
        let typeDesc = describeFileType(ext: ext, isDirectory: isDirectory)
        
        return ScanResultItem(
            name: url.lastPathComponent,
            path: url,
            size: size,
            category: .largeFiles,
            status: .possibleCandidate,
            explanation: "\(typeDesc) (\(ByteFormatter.string(from: size))). Personal file. MacClean does not recommend deleting this automatically.",
            confidence: .medium,
            isRegenerable: false,
            structuredExplanation: CleanupExplanation(
                whatIsIt: "\(typeDesc) on your Mac.",
                whyDetected: "Size exceeds the \(thresholdName) discovery threshold.",
                canRegenerate: false,
                consequence: "Moving this item to Trash will remove this personal file or media. Review carefully before taking action."
            ),
            filesystemIdentity: FilesystemIdentity(url: url)
        )
    }
    
    private func describeFileType(ext: String, isDirectory: Bool) -> String {
        if isDirectory { return "Large Directory" }
        switch ext {
        case "dmg", "iso", "pkg":
            return "Disk Image / Installer"
        case "zip", "tar", "gz", "rar", "7z", "bz2", "xz":
            return "Compressed Archive"
        case "mov", "mp4", "mkv", "avi", "m4v", "wmv":
            return "Video File"
        case "wav", "mp3", "flac", "aif", "m4a":
            return "Audio File"
        case "vmdk", "ova", "qcow2", "raw", "img":
            return "Virtual Machine Disk"
        case "pdf", "psd", "ai", "sketch", "prproj", "fcpx":
            return "Document / Project File"
        default:
            return "Large User File"
        }
    }
    
    func discoverStorageBreakdown(usedSpace: Int64) async -> (breakdown: StorageBreakdown, topConsumers: [TopSpaceConsumer]) {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        // 1. Calculate Applications size
        let appDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            homeDir.appendingPathComponent("Applications")
        ]
        var appsBytes: Int64 = 0
        for dir in appDirs {
            appsBytes += await shallowDirectorySize(at: dir)
        }
        
        // 2. Calculate User Files size
        let userDirs = [
            ("Downloads", homeDir.appendingPathComponent("Downloads")),
            ("Documents", homeDir.appendingPathComponent("Documents")),
            ("Desktop", homeDir.appendingPathComponent("Desktop")),
            ("Movies", homeDir.appendingPathComponent("Movies")),
            ("Pictures", homeDir.appendingPathComponent("Pictures")),
            ("Music", homeDir.appendingPathComponent("Music"))
        ]
        var userFilesBytes: Int64 = 0
        var consumerCandidates: [TopSpaceConsumer] = []
        
        for (label, dir) in userDirs {
            let size = await fastDirectorySize(at: dir, maxFiles: 200)
            userFilesBytes += size
            if size > 500_000_000 { // > 500 MB
                consumerCandidates.append(
                    TopSpaceConsumer(
                        name: label,
                        path: dir,
                        size: size,
                        categoryDescription: "Your Files"
                    )
                )
            }
        }
        
        // 3. Calculate Caches size
        let cachesDir = homeDir.appendingPathComponent("Library/Caches")
        let cachesBytes = await fastDirectorySize(at: cachesDir, maxFiles: 200)
        if cachesBytes > 500_000_000 {
            consumerCandidates.append(
                TopSpaceConsumer(
                    name: "User Caches",
                    path: cachesDir,
                    size: cachesBytes,
                    categoryDescription: "Caches"
                )
            )
        }
        
        // 4. Calculate Developer Data size
        let devDirs = [
            ("Xcode DerivedData", homeDir.appendingPathComponent("Library/Developer/Xcode/DerivedData")),
            ("Xcode Archives", homeDir.appendingPathComponent("Library/Developer/Xcode/Archives")),
            ("Android SDK & Data", homeDir.appendingPathComponent(".android")),
            ("Android Studio Caches", homeDir.appendingPathComponent("Library/Caches/Google")),
            ("Gradle Caches", homeDir.appendingPathComponent(".gradle")),
            ("npm Cache", homeDir.appendingPathComponent(".npm")),
            ("Docker Data", homeDir.appendingPathComponent("Library/Containers/com.docker.docker")),
            ("Colima VM", homeDir.appendingPathComponent(".colima"))
        ]
        var developerBytes: Int64 = 0
        for (label, dir) in devDirs {
            let size = await fastDirectorySize(at: dir, maxFiles: 200)
            developerBytes += size
            if size > 500_000_000 {
                consumerCandidates.append(
                    TopSpaceConsumer(
                        name: label,
                        path: dir,
                        size: size,
                        categoryDescription: "Developer Data"
                    )
                )
            }
        }
        
        // 5. Calculate App Data size (Application Support, Containers)
        let appSupportDir = homeDir.appendingPathComponent("Library/Application Support")
        let containersDir = homeDir.appendingPathComponent("Library/Containers")
        
        let appSupportBytes = await shallowDirectorySize(at: appSupportDir)
        let containersBytes = await shallowDirectorySize(at: containersDir)
        let appDataBytes = appSupportBytes + containersBytes
        
        // Inspect top App Data subfolders
        if let appSupportContents = try? fileManager.contentsOfDirectory(at: appSupportDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            for subURL in appSupportContents.prefix(10) {
                let size = await fastDirectorySize(at: subURL, maxFiles: 150)
                if size > 500_000_000 {
                    consumerCandidates.append(
                        TopSpaceConsumer(
                            name: subURL.lastPathComponent,
                            path: subURL,
                            size: size,
                            categoryDescription: "App Data"
                        )
                    )
                }
            }
        }
        
        // 6. System & Other
        let accountedFor = appsBytes + userFilesBytes + appDataBytes + cachesBytes + developerBytes
        let systemAndOtherBytes = max(0, usedSpace - accountedFor)
        
        let breakdown = StorageBreakdown(
            applicationsBytes: appsBytes,
            userFilesBytes: userFilesBytes,
            appDataBytes: appDataBytes,
            cachesBytes: cachesBytes,
            developerDataBytes: developerBytes,
            systemAndOtherBytes: systemAndOtherBytes,
            totalUsedBytes: usedSpace
        )
        
        // Deduplicate and rank top consumers
        let sortedConsumers = consumerCandidates
            .sorted { $0.size > $1.size }
            .prefix(8)
        
        return (breakdown, Array(sortedConsumers))
    }
    
    private func fastDirectorySize(at url: URL, maxFiles: Int = 200) async -> Int64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        if !isDir.boolValue {
            if let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isSymbolicLinkKey]),
               values.isSymbolicLink != true, let size = values.fileSize {
                return Int64(size)
            }
            return 0
        }
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey],
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        var count = 0
        while let file = enumerator.nextObject() as? URL {
            if Task.isCancelled { break }
            count += 1
            if count > maxFiles { break }
            if enumerator.level > 2 {
                enumerator.skipDescendants()
                continue
            }
            if let values = try? file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]),
               values.isSymbolicLink != true, values.isRegularFile == true, let size = values.fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }
    
    private func shallowDirectorySize(at dir: URL) async -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        var total: Int64 = 0
        var count = 0
        for item in contents {
            if Task.isCancelled { break }
            count += 1
            if count > 25 { break }
            if let values = try? item.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
               values.isRegularFile == true, let size = values.fileSize {
                total += Int64(size)
            } else {
                total += await fastDirectorySize(at: item, maxFiles: 60)
            }
        }
        return total
    }
}
