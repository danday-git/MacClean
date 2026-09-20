import SwiftUI

struct BentoCategoryCard: View {
    let category: CleanupCategory
    let items: [ScanResultItem]
    @ObservedObject var selection: CleanupSelectionViewModel
    @ObservedObject private var languageManager = LanguageManager.shared
    var isFilterActive: Bool = false
    var onFilterSelected: (() -> Void)? = nil
    var onSelectionChanged: (() -> Void)? = nil
    
    private var eligibleItems: [ScanResultItem] {
        items.filter { $0.isEligibleForCleanup }
    }
    
    private var displayBytes: Int64 {
        if category == .largeFiles {
            return items.reduce(0) { $0 + $1.size }
        } else {
            return eligibleItems.reduce(0) { $0 + $1.size }
        }
    }
    
    private var isCategorySelected: Bool {
        guard !eligibleItems.isEmpty else { return false }
        return selection.isAllSelected(in: eligibleItems)
    }
    
    private var iconName: String {
        switch category {
        case .appLeftovers: return "trash.circle.fill"
        case .caches: return "bolt.shield.fill"
        case .developerData: return "hammer.circle.fill"
        case .largeFiles: return "doc.badge.gearshape.fill"
        }
    }
    
    private var titleText: String {
        category.displayName(for: languageManager.language)
    }
    
    private var subtitleText: String {
        let isID = languageManager.language == .indonesian
        switch category {
        case .appLeftovers: return isID ? "Bundle data dari app terhapus" : "Data bundles from deleted apps"
        case .caches: return isID ? "Log usang, preview, & WebKit" : "Outdated logs, previews & WebKit"
        case .developerData: return "Xcode, DerivedData, node_modules"
        case .largeFiles: return isID ? "DMG lama, ZIP instalasi >500 MB" : "Old DMGs, install archives >500 MB"
        }
    }
    
    private var statusBadgeText: String {
        let isID = languageManager.language == .indonesian
        switch category {
        case .appLeftovers: return isID ? "Siap" : "Ready"
        case .caches: return isID ? "Siap" : "Ready"
        case .developerData: return isID ? "Periksa" : "Review"
        case .largeFiles: return ">500 MB"
        }
    }
    
    private var countDetailText: String {
        let isID = languageManager.language == .indonesian
        switch category {
        case .appLeftovers:
            return isID ? "\(items.count) item terdeteksi" : "\(items.count) items detected"
        case .caches:
            return isID ? "Aman dibersihkan" : "Safe to clean"
        case .developerData:
            return isID ? "Artefak dapat di-rebuild" : "Rebuildable artifacts"
        case .largeFiles:
            return isID ? "\(items.count) arsip ditemukan" : "\(items.count) archives found"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - Top: Icon & Checkbox
            HStack(alignment: .center) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isFilterActive ? Color.mcCyan.opacity(0.15) : Color.mcSurfaceHigh)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFilterActive ? Color.mcCyan.opacity(0.5) : Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(isFilterActive ? Color.mcCyan : Color.mcOutline)
                }
                
                Spacer()
                
                // Direct Category Checkbox
                Button(action: {
                    selection.toggleSelectAll(in: eligibleItems)
                    onSelectionChanged?()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isCategorySelected ? Color.mcCyan : Color.mcSurfaceHigh)
                            .frame(width: 18, height: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isCategorySelected ? Color.mcCyan : Color.mcOutlineVariant, lineWidth: 1.2)
                            )
                        
                        if isCategorySelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.mcSurfaceLowest)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(eligibleItems.isEmpty)
                .help(languageManager.language == .indonesian ? "Pilih atau batalkan semua item di \(titleText)" : "Select or deselect all items in \(titleText)")
            }
            
            // MARK: - Title & Subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isFilterActive ? Color.mcCyan : Color.mcOnSurface)
                    .lineLimit(1)
                
                Text(subtitleText)
                    .font(.system(size: 12))
                    .foregroundColor(Color.mcOnSurfaceVariant)
                    .lineLimit(1)
            }
            
            Divider()
                .background(Color.mcOutlineVariant.opacity(0.2))
            
            // MARK: - Bottom Readout & Badge
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ByteFormatter.string(from: displayBytes))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.mcOnSurface)
                    
                    Text(countDetailText)
                        .font(.system(size: 11))
                        .foregroundColor(Color.mcOutline)
                }
                
                Spacer()
                
                Text(statusBadgeText)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isCategorySelected ? Color.mcCyan.opacity(0.15) : Color.mcSurfaceHighest)
                    .foregroundColor(isCategorySelected ? Color.mcCyan : Color.mcOutline)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCategorySelected ? Color.mcCyan.opacity(0.5) : Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(isFilterActive ? Color.mcSurfaceHigh.opacity(0.9) : Color.mcSurfaceContainer.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFilterActive ? Color.mcCyan : Color.mcOutlineVariant.opacity(0.25),
                    lineWidth: isFilterActive ? 2 : 1
                )
        )
        .cornerRadius(16)
        .shadow(color: isFilterActive ? Color.mcCyan.opacity(0.15) : Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onFilterSelected?()
        }
    }
}
