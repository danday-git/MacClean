import SwiftUI

struct FileInspectionTableView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var selection: CleanupSelectionViewModel
    @ObservedObject private var languageManager = LanguageManager.shared
    var onSelectionChanged: (() -> Void)? = nil
    
    @State private var hoveredItemId: UUID? = nil
    
    // Items filtered and sorted from the viewModel
    private var allDisplayItems: [ScanResultItem] {
        if let category = viewModel.selectedCategoryFilter {
            return viewModel.filteredAndSortedItems(for: category)
        } else {
            var items: [ScanResultItem] = []
            for cat in CleanupCategory.allCases {
                items.append(contentsOf: viewModel.filteredAndSortedItems(for: cat))
            }
            
            // Re-apply sort across the merged categories
            switch viewModel.selectedSort {
            case .largestFirst:
                items.sort(by: { $0.size > $1.size })
            case .smallestFirst:
                items.sort(by: { $0.size < $1.size })
            case .category:
                items.sort(by: { $0.category.rawValue < $1.category.rawValue })
            case .name:
                items.sort(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
            case .confidence:
                items.sort(by: { (a: ScanResultItem, b: ScanResultItem) -> Bool in
                    let rA = confidenceRank(for: a)
                    let rB = confidenceRank(for: b)
                    if rA != rB {
                        return rA > rB
                    }
                    return a.size > b.size
                })
            }
            return items
        }
    }
    
    private func confidenceRank(for item: ScanResultItem) -> Int {
        switch item.confidence {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        case nil: return 0
        }
    }
    
    private var areAllVisibleSelected: Bool {
        let eligible = allDisplayItems.filter { $0.isEligibleForCleanup }
        guard !eligible.isEmpty else { return false }
        return selection.isAllSelected(in: eligible)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - Toolbar Header
            ViewThatFits(in: .horizontal) {
                // Wide
                HStack(alignment: .center, spacing: 12) {
                    headerTitles
                    Spacer()
                    toolbarControls
                }
                
                // Compact
                VStack(alignment: .leading, spacing: 10) {
                    headerTitles
                    toolbarControls
                }
            }
            .padding(.bottom, 6)
            .overlay(
                Divider().background(Color.mcOutlineVariant.opacity(0.2)),
                alignment: .bottom
            )
            
            // MARK: - Minimal Table Container
            VStack(spacing: 0) {
                // Table Column Header
                tableHeaderView
                
                Divider()
                    .background(Color.mcOutlineVariant.opacity(0.2))
                
                // Table Rows
                if allDisplayItems.isEmpty {
                    emptyItemsPlaceholder
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(allDisplayItems) { item in
                            tableRow(for: item)
                            Divider()
                                .background(Color.mcOutlineVariant.opacity(0.15))
                        }
                    }
                }
            }
            .background(Color.mcSurfaceLowest.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.mcOutlineVariant.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .padding(18)
        .background(Color.mcSurfaceContainer.opacity(0.75))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mcOutlineVariant.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 14, x: 0, y: 4)
    }
    
    // MARK: - Header Titles
    private var headerTitles: some View {
        let isID = languageManager.language == .indonesian
        return VStack(alignment: .leading, spacing: 2) {
            Text(isID ? "Item Rekomendasi Pembersihan" : "Recommended Cleanup Items")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.mcOnSurface)
            Text(isID ? "Ditinjau dan dapat dilepaskan instan tanpa mengganggu kestabilan macOS." : "Reviewed and can be safely reclaimed without affecting macOS stability.")
                .font(.system(size: 12))
                .foregroundColor(Color.mcOnSurfaceVariant)
        }
    }
    
    // MARK: - Toolbar Controls
    private var toolbarControls: some View {
        let isID = languageManager.language == .indonesian
        return HStack(spacing: 8) {
            // Pilih Rekomendasi / Batal Pilih Action
            Button(action: {
                let isAllRecommendedSelected = selection.isAllRecommendedSelected(from: viewModel.categoryItems)
                if isAllRecommendedSelected {
                    selection.clearSelection()
                } else {
                    selection.selectRecommended(in: viewModel.categoryItems)
                }
                onSelectionChanged?()
            }) {
                let selectLabel = selection.isAllRecommendedSelected(from: viewModel.categoryItems) ? (isID ? "Batal Pilih" : "Deselect") : (isID ? "Pilih Rekomendasi" : "Select Recommended")
                Text(selectLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.mcOnSurface)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.mcSurfaceHigh.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.mcCyan.opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Search Input
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(Color.mcOutline)
                
                TextField(isID ? "Filter berkas..." : "Filter files...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(Color.mcOnSurface)
                    .frame(width: 130)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.mcOutline)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.mcSurfaceHigh.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(8)
            
            // Category Filter Picker
            Menu {
                Button(isID ? "Semua Kategori" : "All Categories") {
                    viewModel.selectedCategoryFilter = nil
                }
                Divider()
                ForEach(CleanupCategory.allCases) { cat in
                    Button(cat.displayName(for: languageManager.language)) {
                        viewModel.selectedCategoryFilter = cat
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11))
                    Text(viewModel.selectedCategoryFilter?.displayName(for: languageManager.language) ?? (isID ? "Semua Kategori" : "All Categories"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color.mcOnSurface)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.mcSurfaceHigh.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mcOutlineVariant.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            .menuStyle(.borderlessButton)
            
            // Sort Picker
            Menu {
                ForEach(SortOption.allCases) { sort in
                    Button(sort.displayName(for: languageManager.language)) {
                        viewModel.selectedSort = sort
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11))
                    Text(viewModel.selectedSort.displayName(for: languageManager.language))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color.mcOnSurface)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.mcSurfaceHigh.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mcOutlineVariant.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            .menuStyle(.borderlessButton)
        }
    }
    
    // MARK: - Table Column Header
    private var tableHeaderView: some View {
        HStack(spacing: 12) {
            // Master Checkbox
            Button(action: {
                let eligible = allDisplayItems.filter { $0.isEligibleForCleanup }
                selection.toggleSelectAll(in: eligible)
                onSelectionChanged?()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(areAllVisibleSelected ? Color.mcCyan : Color.mcSurfaceHigh)
                        .frame(width: 16, height: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(areAllVisibleSelected ? Color.mcCyan : Color.mcOutlineVariant, lineWidth: 1)
                        )
                    if areAllVisibleSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.mcSurfaceLowest)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(width: 24, alignment: .center)
            
            let isID = languageManager.language == .indonesian
            Text(isID ? "NAMA BERKAS / KOMPONEN" : "FILE NAME / COMPONENT")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.mcOutline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(isID ? "DIREKTORI SISTEM" : "SYSTEM DIRECTORY")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.mcOutline)
                .frame(maxWidth: 220, alignment: .leading)
            
            Text(isID ? "TINGKAT KEAMANAN" : "SAFETY LEVEL")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.mcOutline)
                .frame(width: 140, alignment: .leading)
            
            Text(isID ? "UKURAN" : "SIZE")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.mcOutline)
                .frame(width: 80, alignment: .trailing)
            
            Text(isID ? "AKSI" : "ACTION")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.mcOutline)
                .frame(width: 44, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.mcSurfaceHigh.opacity(0.4))
    }
    
    // MARK: - Table Row View
    private func tableRow(for item: ScanResultItem) -> some View {
        let isSelected = selection.isSelected(item)
        let isHovered = hoveredItemId == item.id
        
        return HStack(spacing: 12) {
            // Row Checkbox
            Button(action: {
                selection.toggle(item)
                onSelectionChanged?()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.mcCyan : Color.mcSurfaceHigh)
                        .frame(width: 16, height: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isSelected ? Color.mcCyan : Color.mcOutlineVariant, lineWidth: 1)
                        )
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.mcSurfaceLowest)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(!item.isEligibleForCleanup)
            .frame(width: 24, alignment: .center)
            
            // Name & Icon
            HStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.mcSurfaceHigh)
                        .frame(width: 30, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mcOutlineVariant.opacity(0.2), lineWidth: 1)
                        )
                    Image(systemName: iconForItem(item))
                        .font(.system(size: 14))
                        .foregroundColor(colorForItem(item))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.mcOnSurface)
                        .lineLimit(1)
                    
                    Text(item.humanExplanationText(for: languageManager.language))
                        .font(.system(size: 10))
                        .foregroundColor(Color.mcOutline)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Directory Path (Tilde abbreviated)
            Text(abbreviatedPath(item.path.path))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color.mcOutline)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 220, alignment: .leading)
            
            // Security Level Badge
            securityBadge(for: item)
                .frame(width: 140, alignment: .leading)
            
            // Size
            Text(ByteFormatter.string(from: item.size))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.mcOnSurface)
                .frame(width: 80, alignment: .trailing)
            
            // Action (Reveal in Finder)
            let isID = languageManager.language == .indonesian
            Button(action: {
                viewModel.revealInFinder(url: item.path)
            }) {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 12))
                    .foregroundColor(Color.mcOutline)
                    .padding(5)
                    .background(isHovered ? Color.mcSurfaceHighest : Color.clear)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help(isID ? "Buka di Finder" : "Reveal in Finder")
            .frame(width: 44, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isSelected ? Color.mcCyan.opacity(0.06) : (isHovered ? Color.mcSurfaceHigh.opacity(0.3) : Color.clear))
        .onHover { hovering in
            hoveredItemId = hovering ? item.id : nil
        }
    }
    
    // MARK: - Security Badge Subview
    private func securityBadge(for item: ScanResultItem) -> some View {
        let isID = languageManager.language == .indonesian
        if item.isEligibleForCleanup {
            return AnyView(
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.mcEmerald)
                        .frame(width: 6, height: 6)
                    Text(isID ? "Aman (Rekomendasi)" : "Safe (Recommended)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.mcEmerald)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.mcEmerald.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.mcEmerald.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(10)
            )
        } else if item.category == .developerData {
            return AnyView(
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.mcViolet)
                        .frame(width: 6, height: 6)
                    Text(isID ? "Periksa Ulang" : "Review Carefully")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.mcViolet)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.mcVioletContainer.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.mcViolet.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(10)
            )
        } else {
            return AnyView(
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.mcOutline)
                        .frame(width: 6, height: 6)
                    Text(isID ? "Arsip Lama" : "Old Archive")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.mcOutline)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.mcSurfaceHighest)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.mcOutlineVariant.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(10)
            )
        }
    }
    
    // MARK: - Helpers
    private func iconForItem(_ item: ScanResultItem) -> String {
        switch item.category {
        case .appLeftovers: return "trash.circle.fill"
        case .caches: return "bolt.shield.fill"
        case .developerData: return "hammer.circle.fill"
        case .largeFiles: return "doc.badge.gearshape.fill"
        }
    }
    
    private func colorForItem(_ item: ScanResultItem) -> Color {
        switch item.category {
        case .appLeftovers: return Color.mcCyanGlow
        case .caches: return Color.mcViolet
        case .developerData: return Color.mcCyan
        case .largeFiles: return Color.mcCoral
        }
    }
    
    private func abbreviatedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
    
    private var emptyItemsPlaceholder: some View {
        let isID = languageManager.language == .indonesian
        return VStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 28))
                .foregroundColor(Color.mcEmerald)
            Text(isID ? "Tidak ada berkas yang cocok dengan filter" : "No files matching current filter")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.mcOnSurface)
            Text(isID ? "Semua sistem optimal dan tidak ada item tersisa." : "System is optimal and no remaining items found.")
                .font(.system(size: 11))
                .foregroundColor(Color.mcOutline)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(20)
    }
}
