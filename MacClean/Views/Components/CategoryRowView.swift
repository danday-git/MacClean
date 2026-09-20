import SwiftUI

struct CategoryRowView: View {
    let category: CleanupCategory
    let items: [ScanResultItem]?
    @ObservedObject var viewModel: DashboardViewModel
    
    var displayItems: [ScanResultItem] {
        return viewModel.filteredAndSortedItems(for: category)
    }
    
    var totalSize: Int64 {
        displayItems.reduce(0) { $0 + $1.size }
    }
    
    var eligibleSize: Int64 {
        displayItems.filter { $0.isEligibleForCleanup }.reduce(0) { $0 + $1.size }
    }
    
    var isExpanded: Bool {
        viewModel.expandedCategories.contains(category)
    }
    
    var categoryIcon: String {
        switch category {
        case .appLeftovers: return "trash.circle.fill"
        case .caches: return "bolt.shield.fill"
        case .developerData: return "hammer.circle.fill"
        case .largeFiles: return "doc.badge.gearshape.fill"
        }
    }
    
    var categoryColor: Color {
        switch category {
        case .appLeftovers: return .orange
        case .caches: return .blue
        case .developerData: return .purple
        case .largeFiles: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row
            Button(action: {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    viewModel.toggleCategory(category)
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: categoryIcon)
                        .font(.title2)
                        .foregroundColor(categoryColor)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let _ = items {
                            Text("\(displayItems.count) items · \(ByteFormatter.string(from: totalSize)) (\(ByteFormatter.string(from: eligibleSize)) eligible)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Ready to scan")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let _ = items {
                        Text(viewModel.sizeString(for: totalSize))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                        .accessibilityHidden(true)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .interactiveCard(
                scale: 1.008,
                hoverBackground: Color(NSColor.controlBackgroundColor).opacity(0.85),
                hoverBorder: categoryColor.opacity(0.3),
                cornerRadius: 8,
                pointer: true
            )
            .accessibilityLabel("\(category.rawValue), \(displayItems.count) items, \(ByteFormatter.string(from: totalSize))")
            .accessibilityHint(isExpanded ? "Collapse category" : "Expand category")
            
            // Expanded Details
            if isExpanded {
                LazyVStack(spacing: 8) {
                    if category == .largeFiles {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Discovery Threshold:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $viewModel.selectedThreshold) {
                                    ForEach(LargeItemThreshold.allCases) { thresh in
                                        Text(thresh.rawValue).tag(thresh)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 290)
                                .onChange(of: viewModel.selectedThreshold) { _, newThreshold in
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        viewModel.updateThreshold(newThreshold)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                    .padding(.top, 1)
                                Text("Large files are not marked as junk. Personal documents and developer runtimes require manual review. Checkboxes default to unselected. Use 'Finder' to inspect.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.purple.opacity(0.08))
                            .cornerRadius(6)
                        }
                        .padding(.bottom, 4)
                    }
                    
                    if !displayItems.isEmpty {
                        if category != .largeFiles {
                            let eligibleItems = displayItems.filter { $0.isEligibleForCleanup }
                            if !eligibleItems.isEmpty {
                                let isAllCatSelected = viewModel.selection.isAllSelected(in: eligibleItems)
                                HStack {
                                    Text("\(eligibleItems.count) eligible items · \(ByteFormatter.string(from: eligibleSize))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            viewModel.selection.toggleSelectAll(in: eligibleItems)
                                            viewModel.recalculateReclaimable()
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: isAllCatSelected ? "xmark.circle" : "checkmark.circle")
                                            Text(isAllCatSelected ? "Deselect All in \(category.rawValue)" : "Select All in \(category.rawValue)")
                                        }
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                    }
                                    .buttonStyle(.borderless)
                                    .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                                .cornerRadius(6)
                            }
                        }
                        
                        ForEach(displayItems) { item in
                            ItemDetailRow(item: item, viewModel: viewModel, selection: viewModel.selection)
                        }
                    } else if items?.isEmpty == true || displayItems.isEmpty {
                        Text(emptyStateMessage)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        Text("Press 'Scan Storage' to inspect this category.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.leading, 32)
                .padding(.trailing, 10)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 2)
    }
    
    var emptyStateMessage: String {
        if !viewModel.searchText.isEmpty || viewModel.selectedFilter != .all {
            return "No items match the current filter or search criteria."
        }
        switch category {
        case .appLeftovers: return "No data belonging to uninstalled applications was found."
        case .caches: return "No supported application cache data was found."
        case .developerData: return "No developer caches or build artifacts were found."
        case .largeFiles: return "No files or folders exceeding the \(viewModel.selectedThreshold.rawValue) threshold were found."
        }
    }
}

struct ItemDetailRow: View {
    let item: ScanResultItem
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var selection: CleanupSelectionViewModel
    
    @State private var showingWhySheet = false
    @State private var isHovered = false
    
    private var isSelectable: Bool {
        return item.isEligibleForCleanup
    }
    
    private var isLargeItem: Bool {
        return item.size >= 1_073_741_824 // >= 1 GB
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            
            // Selection Checkbox or Protected Icon
            if isSelectable {
                Button(action: {
                    selection.toggle(item)
                    viewModel.recalculateReclaimable()
                }) {
                    Image(systemName: selection.isSelected(item) ? "checkmark.square.fill" : "square")
                        .foregroundColor(selection.isSelected(item) ? .blue : .secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
                .accessibilityLabel(selection.isSelected(item) ? "Deselect \(item.name)" : "Select \(item.name)")
            } else {
                Image(systemName: item.developerType == .xcodeArchives ? "exclamationmark.triangle.fill" : "lock.fill")
                    .foregroundColor(item.developerType == .xcodeArchives ? .orange : .secondary)
                    .font(.system(size: 15))
                    .padding(.top, 2)
                    .frame(width: 16)
                    .accessibilityLabel("Protected item: \(item.name)")
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Large Item Badge (independent of safety)
                    if isLargeItem {
                        HStack(spacing: 3) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 8))
                            Text("Large Item")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    }
                    
                    // Human-Centric Confidence Tier Badge
                    badgeView(
                        title: item.confidenceTier.badgeLabel,
                        icon: item.confidenceTier.iconName,
                        color: item.confidenceTier.color
                    )
                    
                    if item.category == .appLeftovers {
                        badgeView(title: "App Not Found", icon: "xmark.circle.fill", color: .red)
                    }
                    
                    if let owner = item.ownerApplication, item.developerType == nil {
                        Text("App: \(owner)")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
                
                // Sensitive path display: middle-truncated to protect privacy
                Text(item.path.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                // App Leftovers Explanation
                if item.category == .appLeftovers, let app = item.ownerApplication {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption2)
                            Text("Application '\(app)' is not installed on this Mac.")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption2)
                                .padding(.top, 1)
                            Text("Recommendation: This residual data is no longer utilized. It is eligible to be moved to the macOS Trash to reclaim storage.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    )
                    .cornerRadius(6)
                    .padding(.top, 2)
                } else if let exp = item.explanation {
                    Text(exp)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.85))
                        .lineSpacing(2)
                }
                
                // "Why Can't I Select This?" Explanation for disabled candidates
                if !isSelectable {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Why is this item disabled?")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.primary)
                            Text(disabledReason)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.sizeString(for: item.size))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                
                HStack(spacing: 6) {
                    Button(action: {
                        showingWhySheet = true
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "info.circle")
                            Text("Why?")
                        }
                        .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                    .help("Explain why MacClean can or cannot clean this item")
                    .accessibilityLabel("Why can or cannot clean \(item.name)")
                    
                    Button(action: {
                        viewModel.revealInFinder(url: item.path)
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.forward.app")
                            Text("Finder")
                        }
                        .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                    .help("Show item in Finder")
                    .accessibilityLabel("Reveal \(item.name) in Finder")
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor).opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .sheet(isPresented: $showingWhySheet) {
            ItemExplanationSheet(
                item: item,
                onRevealInFinder: {
                    viewModel.revealInFinder(url: item.path)
                },
                onDismiss: {
                    showingWhySheet = false
                }
            )
        }
    }
    
    private func badgeView(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(title)
                .font(.system(size: 9, weight: .bold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(4)
    }
    
    private var disabledReason: String {
        if item.category == .largeFiles {
            return "Personal file or runtime environment. Review carefully in Finder before taking action."
        } else if item.developerType == .xcodeArchives {
            return "Archives contain release builds and debugging symbols. MacClean does not automatically remove them."
        } else if item.developerType == .dockerCache || item.developerType == .colimaData {
            return "Contains virtual machine and container runtime state. Kept protected to avoid container corruption."
        } else if item.status == .protected {
            return "System-protected location required for macOS integrity or system operation."
        } else if item.confidence == .medium {
            return "Requires manual review before selection."
        } else if item.confidence == .low {
            return "Informational data with low deletion confidence."
        }
        return "Protected item not eligible for automatic cleanup."
    }
}
