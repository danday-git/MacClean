import Foundation
import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case largestFirst = "Largest First"
    case smallestFirst = "Smallest First"
    case category = "Category"
    case name = "Name"
    case confidence = "Confidence"
    
    var id: String { rawValue }
}

enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case eligible = "Eligible"
    case review = "Review"
    case protected = "Protected"
    case leftovers = "Leftovers"
    case caches = "Caches"
    case developerData = "Developer Data"
    case largeFiles = "Large Files"
    
    var id: String { rawValue }
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var summary: StorageSummary?
    @Published var scanSummary: ScanSummary?
    @Published var categoryItems: [CleanupCategory: [ScanResultItem]] = [:]
    @Published var scanWarnings: [ScanWarning] = []
    @Published var isScanning = false
    @Published var currentScanningStatus = ""
    @Published var expandedCategories: Set<CleanupCategory> = []
    @Published var selectedItem: ScanResultItem?
    
    // Phase 8: Large Items & Storage Explorer
    @Published var selectedThreshold: LargeItemThreshold = .allLarge
    @Published var storageBreakdown: StorageBreakdown?
    @Published var topSpaceConsumers: [TopSpaceConsumer] = []
    
    // Filtering & Sorting & Search
    @Published var selectedSort: SortOption = .largestFirst
    @Published var selectedFilter: FilterOption = .all
    @Published var searchText: String = ""
    @Published var selectedCategoryFilter: CleanupCategory?
    
    let selection = CleanupSelectionViewModel()
    @Published var scanProgressLog: [String] = []
    
    // Cleanup & History State
    @Published var lastCleanup: CleanupHistoryEntry?
    @Published var lastScan: ScanHistoryEntry?
    @Published var isCleaningUp = false
    @Published var cleanupProgress: (current: Int, total: Int) = (0, 0)
    @Published var cleanupResults: [TrashOperationResult] = []
    @Published var latestCleanupResult: CleanupBeforeAfter?
    @Published var showCleanupSuccessBanner = false
    
    // Scan Checklist & Elapsed Time (Phase 10)
    @Published var scanStages: [ScanStage: ScanStageStatus] = [:]
    @Published var scanElapsedTime: TimeInterval = 0
    private var timerTask: Task<Void, Never>?
    
    private let scanner: StorageScanner
    private let scanCoordinator: ScanCoordinating
    private let historyManager = CleanupHistoryManager()
    private let scanHistoryManager = ScanHistoryManager()
    
    private var scanTask: Task<Void, Never>?
    
    init(
        scanner: StorageScanner = LocalFilesystemScanner(),
        scanCoordinator: ScanCoordinating = DefaultScanCoordinator()
    ) {
        self.scanner = scanner
        self.scanCoordinator = scanCoordinator
        Task {
            await loadInitialStorage()
            await loadHistory()
        }
    }
    
    func loadHistory() async {
        let lastC = await historyManager.lastEntry()
        let lastS = await scanHistoryManager.lastEntry()
        self.lastCleanup = lastC
        self.lastScan = lastS
    }
    
    func loadInitialStorage() async {
        do {
            summary = try await scanner.scanStorage()
        } catch {
            print("Error reading disk capacity: \(error)")
        }
    }
    
    var totalPotentialReclaimable: Int64 {
        let allItems = categoryItems.values.flatMap { $0 }
        return allItems.filter { $0.isEligibleForCleanup }.reduce(0) { $0 + $1.size }
    }
    
    func scan() {
        guard !isScanning else { return }
        isScanning = true
        scanProgressLog = []
        currentScanningStatus = "Analyzing storage..."
        selection.clearSelection()
        scanWarnings = []
        scanElapsedTime = 0
        
        var initialStages: [ScanStage: ScanStageStatus] = [:]
        for stage in ScanStage.allCases {
            initialStages[stage] = .pending
        }
        scanStages = initialStages
        
        let startTime = Date()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard let self = self, !Task.isCancelled else { break }
                let elapsed = Date().timeIntervalSince(startTime)
                self.scanElapsedTime = elapsed
            }
        }
        
        scanTask = Task { [weak self] in
            guard let self = self else { return }
            self.currentScanningStatus = "Reading disk capacity..."
            await self.loadInitialStorage()
            
            let (scanRes, results, warnings) = await self.scanCoordinator.performScan(
                usedSpace: self.summary?.usedSpace ?? 0,
                threshold: self.selectedThreshold,
                progress: { [weak self] status in
                    Task { @MainActor in
                        self?.currentScanningStatus = status
                        self?.scanProgressLog.append(status)
                    }
                },
                stageProgress: { [weak self] stage, status in
                    Task { @MainActor in
                        self?.scanStages[stage] = status
                    }
                }
            )
            
            self.timerTask?.cancel()
            self.timerTask = nil
            
            guard !Task.isCancelled else {
                self.isScanning = false
                self.currentScanningStatus = "Scan cancelled"
                for stage in ScanStage.allCases {
                    if self.scanStages[stage] == .inProgress || self.scanStages[stage] == .pending {
                        self.scanStages[stage] = .skipped
                    }
                }
                return
            }
            
            self.categoryItems = results
            self.scanSummary = scanRes
            self.storageBreakdown = scanRes.storageBreakdown
            self.topSpaceConsumers = scanRes.topConsumers
            self.scanWarnings = warnings
            
            // Auto-select ONLY recommended items (conservative default)
            self.selection.selectRecommended(in: results)
            self.recalculateReclaimable()
            
            self.expandedCategories = Set(results.filter { !$0.value.isEmpty }.map { $0.key })
            
            let historyEntry = ScanHistoryEntry(
                duration: scanRes.scanDuration,
                bytesDetected: scanRes.totalScannedBytes,
                eligibleBytes: scanRes.reclaimableBytes,
                itemCount: results.values.reduce(0) { $0 + $1.count },
                scannerWarningsCount: warnings.count
            )
            await self.scanHistoryManager.saveEntry(historyEntry)
            self.lastScan = historyEntry
            
            self.currentScanningStatus = ""
            self.isScanning = false
        }
    }
    
    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        timerTask?.cancel()
        timerTask = nil
        for stage in ScanStage.allCases {
            if scanStages[stage] == .inProgress || scanStages[stage] == .pending {
                scanStages[stage] = .skipped
            }
        }
        isScanning = false
        currentScanningStatus = "Scan cancelled"
        scanWarnings.append(.scanCancelled)
    }
    
    func recalculateReclaimable() {
        if summary != nil {
            let allItems = categoryItems.values.flatMap { $0 }
            let eligibleSelected = allItems.filter { selection.isSelected($0) && $0.isEligibleForCleanup }
            summary!.reclaimableSpace = eligibleSelected.reduce(0) { $0 + $1.size }
        }
    }
    
    func toggleCategory(_ category: CleanupCategory) {
        if expandedCategories.contains(category) {
            expandedCategories.remove(category)
        } else {
            expandedCategories.insert(category)
        }
    }
    
    func filteredAndSortedItems(for category: CleanupCategory) -> [ScanResultItem] {
        guard let items = categoryItems[category] else { return [] }
        
        // 1. Filter by category filter pill if set
        if let catFilter = selectedCategoryFilter, catFilter != category {
            return []
        }
        
        var result = items
        
        // Filter by threshold when inspecting largeFiles
        if category == .largeFiles {
            result = result.filter { $0.size >= selectedThreshold.minimumBytes }
        }
        
        // 2. Filter by status filter
        switch selectedFilter {
        case .all:
            break
        case .eligible:
            result = result.filter { $0.isEligibleForCleanup }
        case .review:
            result = result.filter { $0.confidence == .medium }
        case .protected:
            result = result.filter { $0.status == .protected || $0.confidence == .low }
        case .leftovers:
            if category != .appLeftovers { return [] }
        case .caches:
            if category != .caches { return [] }
        case .developerData:
            if category != .developerData { return [] }
        case .largeFiles:
            if category != .largeFiles { return [] }
        }
        
        // 3. Filter by search query
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { item in
                item.name.lowercased().contains(query) ||
                item.path.path.lowercased().contains(query) ||
                (item.ownerApplication?.lowercased().contains(query) ?? false) ||
                item.category.rawValue.lowercased().contains(query) ||
                (item.developerType?.rawValue.lowercased().contains(query) ?? false) ||
                (item.explanation?.lowercased().contains(query) ?? false)
            }
        }
        
        // 4. Sort strictly using raw byte values (never formatted strings)
        switch selectedSort {
        case .largestFirst:
            result.sort { $0.size > $1.size }
        case .smallestFirst:
            result.sort { $0.size < $1.size }
        case .category:
            result.sort { $0.category.rawValue < $1.category.rawValue }
        case .name:
            result.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .confidence:
            result.sort { rank(for: $0.confidence) > rank(for: $1.confidence) }
        }
        
        return result
    }
    
    private func rank(for confidence: DetectionConfidence?) -> Int {
        switch confidence {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        case nil: return 0
        }
    }
    
    func performCleanup(plan: CleanupPlan, trashManager: TrashManaging = DefaultTrashManager()) async {
        isCleaningUp = true
        cleanupProgress = (0, plan.items.count)
        cleanupResults = []
        
        // 1. Snapshot Before State
        let beforeFree = summary?.freeSpace ?? 0
        let beforeUsed = summary?.usedSpace ?? 0
        let beforeReclaimable = totalPotentialReclaimable
        
        let results = await trashManager.moveToTrash(items: plan.items) { [weak self] current, total in
            Task { @MainActor in
                self?.cleanupProgress = (current, total)
            }
        }
        
        self.cleanupResults = results
        
        let successfulIDs = Set(results.filter { $0.status == .moved }.map { $0.sourceItem.id })
        let movedItems = plan.items.filter { successfulIDs.contains($0.id) }
        
        var newCategoryItems = self.categoryItems
        for (category, items) in newCategoryItems {
            newCategoryItems[category] = items.filter { !successfulIDs.contains($0.id) }
        }
        self.categoryItems = newCategoryItems
        
        selection.deselectAll(in: movedItems)
        
        let bytesMoved = results.filter { $0.status == .moved }.reduce(0) { $0 + $1.sourceItem.size }
        let successCount = results.filter { $0.status == .moved }.count
        let failureCount = results.filter { $0.status != .moved }.count
        
        if successCount > 0 {
            let entry = CleanupHistoryEntry(id: UUID(), date: Date(), itemCount: successCount, totalBytesMoved: bytesMoved)
            await historyManager.saveEntry(entry)
            await loadHistory()
        }
        
        // Refresh Storage Capacity on disk & recalculate
        await loadInitialStorage()
        recalculateReclaimable()
        
        // 2. Snapshot After State & Category Stats
        let afterFree = summary?.freeSpace ?? 0
        let afterUsed = summary?.usedSpace ?? 0
        let afterReclaimable = totalPotentialReclaimable
        
        var catDict: [CleanupCategory: (count: Int, bytes: Int64)] = [:]
        for item in movedItems {
            let existing = catDict[item.category] ?? (0, 0)
            catDict[item.category] = (existing.count + 1, existing.bytes + item.size)
        }
        let categoryStats = catDict.map { (cat, val) in
            CategoryCleanupStat(category: cat, count: val.count, bytes: val.bytes)
        }.sorted { $0.bytes > $1.bytes }
        
        let beforeAfter = CleanupBeforeAfter(
            beforeFreeBytes: beforeFree,
            afterFreeBytes: afterFree,
            beforeUsedBytes: beforeUsed,
            afterUsedBytes: afterUsed,
            beforeReclaimableBytes: beforeReclaimable,
            afterReclaimableBytes: afterReclaimable,
            bytesMoved: bytesMoved,
            itemsMovedCount: successCount,
            itemsFailedCount: failureCount,
            categoryStats: categoryStats
        )
        
        self.latestCleanupResult = beforeAfter
        if successCount > 0 {
            self.showCleanupSuccessBanner = true
        }
        
        isCleaningUp = false
    }
    
    func openTrashInFinder() {
        if let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first {
            NSWorkspace.shared.open(trashURL)
        }
    }
    
    func dismissCleanupBanner() {
        showCleanupSuccessBanner = false
    }
    
    func revealInFinder(url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    func sizeString(for bytes: Int64) -> String {
        return ByteFormatter.string(from: bytes)
    }
    
    func updateThreshold(_ newThreshold: LargeItemThreshold) {
        guard selectedThreshold != newThreshold else { return }
        selectedThreshold = newThreshold
        
        // If we don't have large files scanned or new threshold needs smaller files than present in memory:
        let currentItems = categoryItems[.largeFiles] ?? []
        let minScanned = currentItems.map { $0.size }.min() ?? Int64.max
        if currentItems.isEmpty || newThreshold.minimumBytes < minScanned {
            scan()
        }
        // Otherwise, filteredAndSortedItems filters in-memory instantaneously!
    }
}
