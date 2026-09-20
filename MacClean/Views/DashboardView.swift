import SwiftUI

enum DashboardTab: String, CaseIterable, Identifiable {
    case clean = "Smart Clean"
    case explore = "Storage Explorer"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .clean: return "sparkles"
        case .explore: return "chart.pie.fill"
        }
    }
}

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab: DashboardTab = .clean
    @State private var showingRecommendationModal = false
    @State private var showingDirectReview = false
    @State private var recommendedCount = 0
    @State private var recommendedBytes: Int64 = 0
    
    var body: some View {
        VStack(spacing: 0) {
            topAppBar
            
            Divider()
            
            // Responsive Tab Content with Spring Transition
            Group {
                switch selectedTab {
                case .clean:
                    cleanTabScrollView
                        .transition(.opacity.combined(with: .scale(scale: 0.99)))
                case .explore:
                    exploreTabScrollView
                        .transition(.opacity.combined(with: .scale(scale: 0.99)))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedTab)
            
            Divider()
            
            // Contextual Bottom Action Bar
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
    
    // MARK: - Top App Bar (Scalable with ViewThatFits)
    private var topAppBar: some View {
        ViewThatFits(in: .horizontal) {
            // Layout 1: Wide Layout
            HStack(alignment: .center, spacing: 16) {
                appTitleView
                
                Spacer()
                
                segmentedTabPicker
                    .frame(width: 280)
                
                if viewModel.isScanning {
                    scanningStatusView
                }
            }
            
            // Layout 2: Compact / Narrow Window Layout
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    appTitleView
                    Spacer()
                    if viewModel.isScanning {
                        scanningStatusView
                    }
                }
                
                segmentedTabPicker
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isScanning)
    }
    
    private var appTitleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("MacClean")
                .font(.system(size: 21, weight: .bold))
            Text("Storage Intelligence & Safe Cleanup")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var segmentedTabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(DashboardTab.allCases) { tab in
                Label(tab.rawValue, systemImage: tab.icon).tag(tab)
            }
        }
        .pickerStyle(.segmented)
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
            .frame(maxWidth: 160, alignment: .leading)
            
            Button("Cancel") {
                viewModel.cancelScan()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    // MARK: - Smart Clean Tab (Simple, Fluid & Scalable)
    private var cleanTabScrollView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                commonBanners
                
                if let summary = viewModel.summary {
                    // Fluid Storage Overview Bar
                    StorageHeroHeaderView(
                        summary: summary,
                        reclaimableBytes: viewModel.totalPotentialReclaimable
                    )
                    
                    // Recommended Cleanup Card or Clean State Reassurance
                    rightColumnActionHero(summary: summary)
                    
                    // Category Breakdown Cards
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Categories")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    selectedTab = .explore
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Open Storage Explorer")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                            }
                            .buttonStyle(.link)
                        }
                        
                        bentoCategoryGrid
                    }
                } else {
                    loadingStoragePlaceholder
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Storage Explorer Tab
    private var exploreTabScrollView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                commonBanners
                
                if let summary = viewModel.summary {
                    // Storage Explorer (Composition & Top Space Consumers)
                    if let breakdown = viewModel.storageBreakdown {
                        StorageExplorerView(
                            breakdown: breakdown,
                            topConsumers: viewModel.topSpaceConsumers,
                            onRevealInFinder: { url in
                                viewModel.revealInFinder(url: url)
                            }
                        )
                    } else {
                        StorageBarView(summary: summary, viewModel: viewModel)
                    }
                    
                    // Visual Category Filter Chips (Adaptive Grid)
                    visualCategoryFilterRow
                    
                    // Search, Filter & Sort Toolbar (Responsive ViewThatFits)
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
                } else {
                    loadingStoragePlaceholder
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Common Banners
    @ViewBuilder
    private var commonBanners: some View {
        // Post-Cleanup Success Banner
        if viewModel.showCleanupSuccessBanner, let result = viewModel.latestCleanupResult {
            cleanupSuccessBanner(result: result)
        }
        
        // Live Scanning Checklist & Progress
        if viewModel.isScanning {
            ScanningProgressCard(viewModel: viewModel)
        }
        
        // Partial Scan / Permission Resilience Banner
        if !viewModel.scanWarnings.isEmpty && !viewModel.isScanning {
            scanWarningBanner
        }
    }
    
    // MARK: - Right Column Bento Action Hero
    @ViewBuilder
    private func rightColumnActionHero(summary: StorageSummary) -> some View {
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
    
    // MARK: - Clean State Card (Sleek High-Confidence Status)
    private var cleanStateCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Mac is Clean & Optimized")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("No orphaned app leftovers or redundant cache files were detected.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selectedTab = .explore
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("Explore Files")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Divider()
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .font(.caption2)
                    Text("Ready for next scan")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                        .font(.caption2)
                    Text("100% Native Trash Safety")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    // MARK: - Bento Category Grid (Fluid Adaptive Cards)
    private var bentoCategoryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 10)],
            spacing: 10
        ) {
            ForEach(CleanupCategory.allCases) { category in
                BentoCategoryCard(
                    category: category,
                    items: viewModel.categoryItems[category] ?? [],
                    totalEligibleOverall: viewModel.totalPotentialReclaimable,
                    onExplore: {
                        viewModel.selectedCategoryFilter = category
                        if !viewModel.expandedCategories.contains(category) {
                            viewModel.expandedCategories.insert(category)
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            selectedTab = .explore
                        }
                    }
                )
            }
        }
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
    
    // MARK: - Contextual Bottom Bar (Responsive ViewThatFits)
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            if selectedTab == .explore {
                // Selection Toolbar in Explore tab for custom manual review
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
            }
            
            ViewThatFits(in: .horizontal) {
                // Wide Layout
                HStack {
                    safetyPolicyText
                    Spacer()
                    scanStorageButton
                }
                
                // Compact Layout
                VStack(spacing: 8) {
                    scanStorageButton
                        .frame(maxWidth: .infinity)
                    safetyPolicyText
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
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
    
    private var scanStorageButton: some View {
        Button(action: {
            viewModel.scan()
        }) {
            HStack(spacing: 6) {
                if viewModel.isScanning {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Scanning Mac...")
                } else {
                    Image(systemName: "magnifyingglass")
                    Text("Scan Storage")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isScanning)
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
                Text("No items selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("·")
                    .foregroundColor(.secondary)
                Text("Potential reclaimable: \(ByteFormatter.string(from: viewModel.totalPotentialReclaimable))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        } else {
            HStack(spacing: 6) {
                Text("\(selection.selectedItems.count) items selected")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("·")
                    .foregroundColor(.secondary)
                Text("\(ByteFormatter.string(from: selection.selectedSize(from: viewModel.categoryItems))) reclaimable")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
        }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        if selection.selectedItems.isEmpty {
            Button(action: onSelectRecommended) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                    Text(viewModel.totalPotentialReclaimable > 0 ? "Review \(ByteFormatter.string(from: viewModel.totalPotentialReclaimable))" : "Review Cleanup")
                        .fontWeight(.semibold)
                }
            }
            .accessibilityLabel(viewModel.totalPotentialReclaimable > 0 ? "Review \(ByteFormatter.string(from: viewModel.totalPotentialReclaimable)) of eligible cleanup items" : "Review Cleanup")
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(viewModel.totalPotentialReclaimable == 0)
        } else {
            HStack(spacing: 12) {
                Button("Clear Selection") {
                    selection.clearSelection()
                    viewModel.recalculateRecalculateReclaimable()
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                Button("Review \(ByteFormatter.string(from: selection.selectedSize(from: viewModel.categoryItems)))") {
                    showingReview = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
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
