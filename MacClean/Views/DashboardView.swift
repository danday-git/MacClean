import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingRecommendationModal = false
    @State private var showingDirectReview = false
    @State private var recommendedCount = 0
    @State private var recommendedBytes: Int64 = 0
    
    var body: some View {
        VStack(spacing: 0) {
            topAppBar
            
            Divider()
            
            unifiedDashboardScrollView
            
            Divider()
            
            bottomActionBar
        }
        .frame(minWidth: 600, minHeight: 460)
        .sheet(isPresented: $showingRecommendationModal) {
            RecommendationExplanationView(
                count: recommendedCount,
                bytes: recommendedBytes,
                onConfirm: {
                    viewModel.selection.selectRecommended(in: viewModel.categoryItems)
                    viewModel.recalculateReclaimable()
                    showingRecommendationModal = false
                    showingDirectReview = true
                },
                onDismiss: {
                    showingRecommendationModal = false
                }
            )
        }
        .sheet(isPresented: $showingDirectReview) {
            ReviewCleanupView(
                viewModel: viewModel,
                selection: viewModel.selection,
                isPresented: $showingDirectReview
            )
        }
    }
    
    // MARK: - Top App Bar (Clean macOS Toolbar)
    private var topAppBar: some View {
        HStack(alignment: .center, spacing: 16) {
            appTitleView
            
            Spacer()
            
            if viewModel.isScanning {
                scanningStatusView
            } else {
                scanStorageButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isScanning)
    }
    
    private var appTitleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("MacClean")
                .font(.system(size: 20, weight: .bold))
            Text("Storage Intelligence & Safe Cleanup")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var scanStorageButton: some View {
        Button(action: {
            viewModel.scan()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle.magnifyingglass")
                Text("Scan Storage")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .pointerCursor()
    }
    
    private var scanningStatusView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.currentScanningStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !viewModel.scanProgressLog.isEmpty {
                    Text(viewModel.scanProgressLog.last ?? "")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: 180, alignment: .leading)
            
            Button("Cancel") {
                viewModel.cancelScan()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    // MARK: - Banners
    @ViewBuilder
    private var commonBanners: some View {
        if let result = viewModel.latestCleanupResult, viewModel.showCleanupSuccessBanner {
            cleanupSuccessBanner(result: result)
        }
        
        if !viewModel.scanWarnings.isEmpty {
            scanWarningBanner
        }
    }
    
    // MARK: - Unified Dashboard ScrollView
    private var unifiedDashboardScrollView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                commonBanners
                
                if let summary = viewModel.summary {
                    // 1. Storage Overview Bar (Macintosh HD, APFS, Used, Free, Cleanable)
                    StorageHeroHeaderView(
                        summary: summary,
                        reclaimableBytes: viewModel.totalPotentialReclaimable
                    )
                    
                    // 2. Safe Cleanup Recommendation (1-Click Clean)
                    cleanupRecommendationSection
                    
                    // 3. Storage Composition & Top Space Consumers
                    if let breakdown = viewModel.storageBreakdown {
                        StorageExplorerView(
                            breakdown: breakdown,
                            topConsumers: viewModel.topSpaceConsumers,
                            onRevealInFinder: { url in
                                viewModel.revealInFinder(url: url)
                            }
                        )
                    }
                    
                    // 4. Detailed File Inspector (Search, Filter, Categories)
                    fileInspectorSection
                } else {
                    loadingStoragePlaceholder
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Safe Cleanup Recommendation Section
    @ViewBuilder
    private var cleanupRecommendationSection: some View {
        if viewModel.totalPotentialReclaimable > 0 {
            let leftoverItems = viewModel.categoryItems[.appLeftovers]?.filter { $0.isEligibleForCleanup } ?? []
            let cacheItems = viewModel.categoryItems[.caches]?.filter { $0.isEligibleForCleanup } ?? []
            let devItems = viewModel.categoryItems[.developerData]?.filter { $0.isEligibleForCleanup } ?? []
            
            RecommendedCleanupCard(
                leftoverBytes: leftoverItems.reduce(0) { $0 + $1.size },
                cacheBytes: cacheItems.reduce(0) { $0 + $1.size },
                devCacheBytes: devItems.reduce(0) { $0 + $1.size },
                totalReclaimableBytes: viewModel.totalPotentialReclaimable,
                onReviewRecommended: {
                    viewModel.selection.selectRecommended(in: viewModel.categoryItems)
                    viewModel.recalculateReclaimable()
                    showingDirectReview = true
                }
            )
        } else if !viewModel.isScanning {
            cleanStateCard
        }
    }
    
    // MARK: - Clean State Card
    private var cleanStateCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Mac is Clean & Optimized")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("No unneeded cache files or orphaned app leftovers were detected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Verified Safe")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
                .foregroundColor(.green)
                .cornerRadius(6)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    // MARK: - File Inspector Section (Search, Filter, Categories)
    private var fileInspectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Candidate Files & Detailed Inspection")
                        .font(.headline)
                    Text("Inspect individual files, search by name or path, and customize selection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Visual Category Filter Chips
            visualCategoryFilterRow
            
            // Search, Filter & Sort Toolbar
            explorerToolbar
            
            // Category Breakdown Accordions (With LazyVStack row rendering)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(CleanupCategory.allCases) { category in
                    CategoryRowView(
                        category: category,
                        items: viewModel.categoryItems[category],
                        viewModel: viewModel
                    )
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor).opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    // MARK: - Visual Category Filter Row (Storage Explorer - Adaptive Grid)
    private var visualCategoryFilterRow: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: .infinity), spacing: 10)], spacing: 10) {
            ForEach(CleanupCategory.allCases) { category in
                let catItems = viewModel.categoryItems[category] ?? []
                let catDisplayBytes = category == .largeFiles
                    ? catItems.reduce(0) { $0 + $1.size }
                    : catItems.filter { $0.isEligibleForCleanup }.reduce(0) { $0 + $1.size }
                let isSelected = viewModel.selectedCategoryFilter == category
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        if isSelected {
                            viewModel.selectedCategoryFilter = nil
                        } else {
                            viewModel.selectedCategoryFilter = category
                            if !viewModel.expandedCategories.contains(category) {
                                viewModel.expandedCategories.insert(category)
                            }
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text(ByteFormatter.string(from: catDisplayBytes))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if isSelected {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? Color.blue.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .interactiveCard(
                    scale: 1.015,
                    hoverBackground: Color.blue.opacity(0.06),
                    hoverBorder: isSelected ? Color.blue : Color.secondary.opacity(0.2),
                    cornerRadius: 8,
                    pointer: true
                )
            }
        }
    }
    
    // MARK: - Explorer Toolbar (Search, Filter, Sort - Responsive ViewThatFits)
    private var explorerToolbar: some View {
        ViewThatFits(in: .horizontal) {
            // Wide Layout: Single horizontal line
            HStack(spacing: 12) {
                searchFieldView
                    .frame(minWidth: 160, maxWidth: 280)
                
                filterPickerView
                
                Spacer()
                
                sortPickerView
            }
            
            // Compact Layout: Two rows for small windows
            VStack(alignment: .leading, spacing: 8) {
                searchFieldView
                    .frame(maxWidth: .infinity)
                
                HStack {
                    filterPickerView
                    Spacer()
                    sortPickerView
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var searchFieldView: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.caption)
            TextField("Search candidates...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    private var filterPickerView: some View {
        Picker("", selection: $viewModel.selectedFilter) {
            ForEach(FilterOption.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 140)
    }
    
    private var sortPickerView: some View {
        HStack(spacing: 4) {
            Text("Sort:")
                .font(.caption)
                .foregroundColor(.secondary)
            Picker("", selection: $viewModel.selectedSort) {
                ForEach(SortOption.allCases) { sort in
                    Text(sort.rawValue).tag(sort)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 130)
        }
    }
    
    // MARK: - Unified Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            SelectionToolbarView(
                viewModel: viewModel,
                selection: viewModel.selection,
                onSelectRecommended: {
                    let summary = viewModel.selection.recommendedSummary(from: viewModel.categoryItems)
                    recommendedCount = summary.count
                    recommendedBytes = summary.totalBytes
                    showingRecommendationModal = true
                }
            )
            
            Divider()
            
            HStack {
                safetyPolicyText
                Spacer()
                if let last = viewModel.lastScan {
                    Text("Last scan: \(last.formattedDate)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
    
    private var safetyPolicyText: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(.green)
                .font(.caption)
            Text("Safety Policy: Files are moved to macOS Trash, never permanently deleted.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helpers & Banners
    private func cleanupSuccessBanner(result: CleanupBeforeAfter) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 26))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Cleanup Successful • \(ByteFormatter.string(from: result.bytesMoved)) Moved to Trash")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.dismissCleanupBanner()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss notification")
                }
                
                HStack(spacing: 6) {
                    Text("Free space: \(ByteFormatter.string(from: result.beforeFreeBytes)) → \(ByteFormatter.string(from: result.effectiveAfterFreeBytes))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("(+\(ByteFormatter.string(from: result.freeSpaceGain)) gained)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(result.itemsMovedCount) items cleaned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Text("Files are safe in macOS Trash. Empty Trash in Finder to permanently release physical space.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.openTrashInFinder()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.caption2)
                            Text("Open Trash")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.link)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private var scanWarningBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Some folders couldn't be inspected")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text("macOS restricted access to some folders. MacClean skipped them safely and can still show results from the areas it could access.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var loadingStoragePlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Reading macOS storage information...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }
    
    private func iconForCategory(_ category: CleanupCategory) -> String {
        switch category {
        case .appLeftovers: return "trash.circle.fill"
        case .caches: return "bolt.shield.fill"
        case .developerData: return "hammer.circle.fill"
        case .largeFiles: return "doc.badge.gearshape.fill"
        }
    }
    
    private func colorForCategory(_ category: CleanupCategory) -> Color {
        switch category {
        case .appLeftovers: return .orange
        case .caches: return .blue
        case .developerData: return .purple
        case .largeFiles: return .green
        }
    }
}

// MARK: - Selection Toolbar View (Responsive ViewThatFits)
struct SelectionToolbarView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var selection: CleanupSelectionViewModel
    var onSelectRecommended: () -> Void
    @State private var showingReview = false
    
    private var totalEligibleBytes: Int64 {
        viewModel.totalPotentialReclaimable
    }
    
    private var selectedBytes: Int64 {
        selection.selectedSize(from: viewModel.categoryItems)
    }
    
    private var isAllSelected: Bool {
        selection.isAllRecommendedSelected(from: viewModel.categoryItems)
    }
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Wide Layout
            HStack {
                selectionInfoView
                Spacer()
                actionButtonsView
            }
            
            // Compact Layout
            VStack(alignment: .leading, spacing: 8) {
                selectionInfoView
                HStack {
                    Spacer()
                    actionButtonsView
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private var selectionInfoView: some View {
        if selection.selectedItems.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("0 items selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("·")
                    .foregroundColor(.secondary)
                Text("\(ByteFormatter.string(from: totalEligibleBytes)) available to clean")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(selection.selectedItems.count) items selected")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("·")
                    .foregroundColor(.secondary)
                Text("\(ByteFormatter.string(from: selectedBytes)) selected to clean")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
        }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // 1. Select All / Deselect All Controls
            if selection.selectedItems.isEmpty {
                Button(action: {
                    selection.selectRecommended(in: viewModel.categoryItems)
                    viewModel.recalculateReclaimable()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle")
                        Text(totalEligibleBytes > 0 ? "Select All (\(ByteFormatter.string(from: totalEligibleBytes)))" : "Select All")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(totalEligibleBytes == 0)
                .help("Select all eligible cache and leftover items")
            } else {
                Button("Deselect All") {
                    selection.clearSelection()
                    viewModel.recalculateReclaimable()
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                if !isAllSelected && totalEligibleBytes > selectedBytes {
                    Button("Select All") {
                        selection.selectRecommended(in: viewModel.categoryItems)
                        viewModel.recalculateReclaimable()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
            
            // 2. Review & Clean Action Button
            Button(action: {
                showingReview = true
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.shield.fill")
                    if selection.selectedItems.isEmpty {
                        Text("Review & Clean")
                            .fontWeight(.semibold)
                    } else {
                        Text("Review & Clean (\(ByteFormatter.string(from: selectedBytes)))")
                            .fontWeight(.semibold)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(selection.selectedItems.isEmpty)
            .help(selection.selectedItems.isEmpty ? "Select items first to review and clean" : "Review selected items before moving them to Trash")
            .sheet(isPresented: $showingReview) {
                ReviewCleanupView(
                    viewModel: viewModel,
                    selection: selection,
                    isPresented: $showingReview
                )
            }
        }
    }
}

// Extension to avoid typo
private extension DashboardViewModel {
    func recalculateRecalculateReclaimable() {
        self.recalculateReclaimable()
    }
}

struct RecommendationExplanationView: View {
    let count: Int
    let bytes: Int64
    var onConfirm: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title)
                    .foregroundColor(.green)
                Text("Recommended Cleanup")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top, 8)
            
            Text("MacClean identified \(count) high-confidence items totaling \(ByteFormatter.string(from: bytes)).")
                .font(.body)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Includes known regenerable caches and verified application leftovers.")
                        .font(.caption)
                }
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Excludes protected runtimes, archives, and items requiring manual review.")
                        .font(.caption)
                }
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Files will be moved to the macOS Trash upon your explicit review and confirmation.")
                        .font(.caption)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Apply Selection") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 440)
    }
}
