import SwiftUI

struct BentoCategoryCard: View {
    let category: CleanupCategory
    let items: [ScanResultItem]
    @ObservedObject var selection: CleanupSelectionViewModel
    var onFilterSelected: (() -> Void)? = nil
    
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
        switch category {
        case .appLeftovers: return "Sisa Aplikasi"
        case .caches: return "Cache Sistem"
        case .developerData: return "Data Pengembang"
        case .largeFiles: return "Berkas & Arsip Besar"
        }
    }
    
    private var subtitleText: String {
        switch category {
        case .appLeftovers: return "Bundle data dari app terhapus"
        case .caches: return "Log usang, preview, & WebKit"
        case .developerData: return "Xcode, DerivedData, node_modules"
        case .largeFiles: return "DMG lama, ZIP instalasi >500 MB"
        }
    }
    
    private var statusBadgeText: String {
        switch category {
        case .appLeftovers: return "Siap"
        case .caches: return "Siap"
        case .developerData: return "Periksa"
        case .largeFiles: return ">500 MB"
        }
    }
    
    private var countDetailText: String {
        switch category {
        case .appLeftovers:
            return "\(items.count) item terdeteksi"
        case .caches:
            return "Aman dibersihkan"
        case .developerData:
            return "Rebuildable artifacts"
        case .largeFiles:
            return "\(items.count) arsip ditemukan"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - Top: Icon & Checkbox
            HStack(alignment: .center) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.mcSurfaceHigh)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(isCategorySelected ? Color.mcCyan : Color.mcOutline)
                }
                
                Spacer()
                
                // Direct Category Checkbox
                Button(action: {
                    selection.toggleSelectAll(in: eligibleItems)
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
                .help("Pilih atau batalkan semua item di \(titleText)")
            }
            
            // MARK: - Title & Subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.mcOnSurface)
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
                    .background(Color.mcSurfaceHighest)
                    .foregroundColor(isCategorySelected ? Color.mcCyan : Color.mcOutline)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.mcSurfaceContainer.opacity(isCategorySelected ? 0.9 : 0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCategorySelected ? Color.mcCyan.opacity(0.4) : Color.mcOutlineVariant.opacity(0.25),
                    lineWidth: isCategorySelected ? 1.5 : 1
                )
        )
        .cornerRadius(16)
        .shadow(color: isCategorySelected ? Color.mcCyan.opacity(0.06) : Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onFilterSelected?()
        }
    }
}
