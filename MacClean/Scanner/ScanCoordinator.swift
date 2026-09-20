import Foundation

protocol ScanCoordinating: Sendable {
    func performScan(
        usedSpace: Int64,
        threshold: LargeItemThreshold,
        progress: @escaping @Sendable (String) -> Void,
        stageProgress: (@Sendable (ScanStage, ScanStageStatus) -> Void)?
    ) async -> (summary: ScanSummary, items: [CleanupCategory: [ScanResultItem]], warnings: [ScanWarning])
}

extension ScanCoordinating {
    func performScan(
        usedSpace: Int64,
        threshold: LargeItemThreshold,
        progress: @escaping @Sendable (String) -> Void
    ) async -> (summary: ScanSummary, items: [CleanupCategory: [ScanResultItem]], warnings: [ScanWarning]) {
        await performScan(usedSpace: usedSpace, threshold: threshold, progress: progress, stageProgress: nil)
    }
    
    func performScan(
        progress: @escaping @Sendable (String) -> Void
    ) async -> (summary: ScanSummary, items: [CleanupCategory: [ScanResultItem]], warnings: [ScanWarning]) {
        await performScan(usedSpace: 0, threshold: .allLarge, progress: progress, stageProgress: nil)
    }
}

actor DefaultScanCoordinator: ScanCoordinating {
    
    private let appScanner: ApplicationScanner
    private let leftoverDetector: AppLeftoverDetecting
    private let cacheScanner: CacheScanner
    private let developerScanner: DeveloperDataScanning
    private let largeItemScanner: LargeItemScanning
    
    init(
        appScanner: ApplicationScanner = DefaultApplicationScanner(),
        leftoverDetector: AppLeftoverDetecting = DefaultAppLeftoverDetector(),
        cacheScanner: CacheScanner = DefaultCacheScanner(),
        developerScanner: DeveloperDataScanning = DefaultDeveloperDataScanner(),
        largeItemScanner: LargeItemScanning = DefaultLargeItemScanner()
    ) {
        self.appScanner = appScanner
        self.leftoverDetector = leftoverDetector
        self.cacheScanner = cacheScanner
        self.developerScanner = developerScanner
        self.largeItemScanner = largeItemScanner
    }
    
    func performScan(
        usedSpace: Int64 = 0,
        threshold: LargeItemThreshold = .allLarge,
        progress: @escaping @Sendable (String) -> Void,
        stageProgress: (@Sendable (ScanStage, ScanStageStatus) -> Void)? = nil
    ) async -> (summary: ScanSummary, items: [CleanupCategory: [ScanResultItem]], warnings: [ScanWarning]) {
        let startTime = CFAbsoluteTimeGetCurrent()
        var warnings: [ScanWarning] = []
        var categoryResults: [CleanupCategory: [ScanResultItem]] = [:]
        var isPartial = false
        
        progress("Starting scan...")
        stageProgress?(.applications, .inProgress)
        
        // 1. Scan Installed Applications & App Leftovers
        var leftovers: [ScanResultItem] = []
        do {
            try Task.checkCancellation()
            progress("Scanning applications...")
            let installedApps = try await appScanner.scanInstalledApplications()
            stageProgress?(.applications, .completed)
            stageProgress?(.leftovers, .inProgress)
            
            try Task.checkCancellation()
            progress("Scanning application leftovers...")
            leftovers = try await leftoverDetector.detectLeftovers(installedApplications: installedApps)
            stageProgress?(.leftovers, .completed)
            progress("Completed application scan.")
        } catch is CancellationError {
            stageProgress?(.applications, .skipped)
            stageProgress?(.leftovers, .skipped)
            warnings.append(.scanCancelled)
            isPartial = true
        } catch {
            stageProgress?(.applications, .failed)
            stageProgress?(.leftovers, .skipped)
            warnings.append(.unavailableLocation(location: "Applications"))
            isPartial = true
        }
        categoryResults[.appLeftovers] = leftovers
        
        // Check for cancellation
        if Task.isCancelled {
            warnings.append(.scanCancelled)
            isPartial = true
            return buildScanResult(startTime: startTime, results: categoryResults, warnings: warnings, isPartial: true, breakdown: nil, topConsumers: [])
        }
        
        // 2. Concurrent Caches, Developer Data, and Large Items Scan
        async let cachesTask: Result<[ScanResultItem], Error> = {
            do {
                try Task.checkCancellation()
                let items = try await self.cacheScanner.scanCaches()
                return .success(items)
            } catch {
                return .failure(error)
            }
        }()
        
        async let developerTask: Result<[ScanResultItem], Error> = {
            do {
                try Task.checkCancellation()
                let items = try await self.developerScanner.scanDeveloperData()
                return .success(items)
            } catch {
                return .failure(error)
            }
        }()
        
        async let largeItemsTask: Result<[ScanResultItem], Error> = {
            do {
                try Task.checkCancellation()
                let items = try await self.largeItemScanner.scanLargeItems(threshold: threshold)
                return .success(items)
            } catch {
                return .failure(error)
            }
        }()
        
        async let explorerTask: (StorageBreakdown, [TopSpaceConsumer]) = {
            await self.largeItemScanner.discoverStorageBreakdown(usedSpace: usedSpace)
        }()
        
        progress("Scanning caches, developer data & large items concurrently...")
        stageProgress?(.caches, .inProgress)
        stageProgress?(.developerData, .inProgress)
        stageProgress?(.largeFiles, .inProgress)
        
        let (cachesResult, developerResult, largeResult, (breakdown, topConsumers)) = await (cachesTask, developerTask, largeItemsTask, explorerTask)
        
        switch cachesResult {
        case .success(let items):
            categoryResults[.caches] = items
            stageProgress?(.caches, .completed)
        case .failure(let error):
            if error is CancellationError {
                warnings.append(.scanCancelled)
                stageProgress?(.caches, .skipped)
            } else {
                warnings.append(.inaccessibleDirectory(location: "Library/Caches"))
                stageProgress?(.caches, .failed)
            }
            categoryResults[.caches] = []
            isPartial = true
        }
        
        switch developerResult {
        case .success(let items):
            categoryResults[.developerData] = items
            stageProgress?(.developerData, .completed)
        case .failure(let error):
            if error is CancellationError {
                warnings.append(.scanCancelled)
                stageProgress?(.developerData, .skipped)
            } else {
                warnings.append(.inaccessibleDirectory(location: "Developer Directories"))
                stageProgress?(.developerData, .failed)
            }
            categoryResults[.developerData] = []
            isPartial = true
        }
        
        switch largeResult {
        case .success(let items):
            categoryResults[.largeFiles] = items
            stageProgress?(.largeFiles, .completed)
        case .failure(let error):
            if error is CancellationError {
                warnings.append(.scanCancelled)
                stageProgress?(.largeFiles, .skipped)
            } else {
                warnings.append(.inaccessibleDirectory(location: "Large Files & Folders"))
                stageProgress?(.largeFiles, .failed)
            }
            categoryResults[.largeFiles] = []
            isPartial = true
        }
        
        // 3. Centralized Canonical Deduplication
        progress("Deduplicating candidates...")
        categoryResults = deduplicate(results: categoryResults)
        
        progress("Finalizing storage explorer results...")
        return buildScanResult(
            startTime: startTime,
            results: categoryResults,
            warnings: warnings,
            isPartial: isPartial,
            breakdown: breakdown,
            topConsumers: topConsumers
        )
    }
    
    func deduplicate(
        results: [CleanupCategory: [ScanResultItem]]
    ) -> [CleanupCategory: [ScanResultItem]] {
        var seenIdentities = Set<FilesystemIdentity>()
        var deduplicatedResults: [CleanupCategory: [ScanResultItem]] = [:]
        
        let priorityCategories: [CleanupCategory] = [.appLeftovers, .caches, .developerData, .largeFiles]
        
        for category in priorityCategories {
            let items = results[category] ?? []
            var uniqueCategoryItems: [ScanResultItem] = []
            
            for item in items {
                let identity = item.identity
                if !seenIdentities.contains(identity) {
                    seenIdentities.insert(identity)
                    uniqueCategoryItems.append(item)
                }
            }
            deduplicatedResults[category] = uniqueCategoryItems
        }
        
        return deduplicatedResults
    }
    
    private func buildScanResult(
        startTime: CFAbsoluteTime,
        results: [CleanupCategory: [ScanResultItem]],
        warnings: [ScanWarning],
        isPartial: Bool,
        breakdown: StorageBreakdown?,
        topConsumers: [TopSpaceConsumer]
    ) -> (summary: ScanSummary, items: [CleanupCategory: [ScanResultItem]], warnings: [ScanWarning]) {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        var totalBytes: Int64 = 0
        var totalEligibleBytes: Int64 = 0
        var categorySummaries: [CategorySummary] = []
        
        for category in CleanupCategory.allCases {
            let items = results[category] ?? []
            let catTotal = items.reduce(0) { $0 + $1.size }
            let catEligible = items.filter { $0.isEligibleForCleanup }.reduce(0) { $0 + $1.size }
            
            totalBytes += catTotal
            totalEligibleBytes += catEligible
            
            categorySummaries.append(
                CategorySummary(
                    category: category,
                    totalBytes: catTotal,
                    eligibleBytes: catEligible,
                    itemCount: items.count
                )
            )
        }
        
        let summary = ScanSummary(
            totalScannedBytes: totalBytes,
            reclaimableBytes: totalEligibleBytes,
            selectedBytes: 0,
            categorySummaries: categorySummaries,
            scanDuration: duration,
            warnings: warnings,
            isPartial: isPartial,
            storageBreakdown: breakdown,
            topConsumers: topConsumers
        )
        
        return (summary, results, warnings)
    }
}
