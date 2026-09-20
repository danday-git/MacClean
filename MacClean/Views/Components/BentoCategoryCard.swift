import SwiftUI

struct BentoCategoryCard: View {
    let category: CleanupCategory
    let items: [ScanResultItem]
    let totalEligibleOverall: Int64
    let onExplore: () -> Void
    
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
    
    private var iconName: String {
        switch category {
        case .appLeftovers: return "trash.circle.fill"
        case .caches: return "bolt.shield.fill"
        case .developerData: return "hammer.circle.fill"
        case .largeFiles: return "doc.badge.gearshape.fill"
        }
    }
    
    private var accentColor: Color {
        switch category {
        case .appLeftovers: return .orange
        case .caches: return .blue
        case .developerData: return .purple
        case .largeFiles: return .green
        }
    }
    
    private var subtitleText: String {
        switch category {
        case .appLeftovers: return "Uninstalled app leftovers"
        case .caches: return "Regenerable app caches"
        case .developerData: return "Build & package caches"
        case .largeFiles: return "Large files & archives"
        }
    }
    
    // Relative proportion (0.0 to 1.0)
    private var relativeShare: Double {
        guard totalEligibleOverall > 0, displayBytes > 0 else { return 0.05 }
        return min(1.0, max(0.08, Double(displayBytes) / Double(totalEligibleOverall)))
    }
    
    var body: some View {
        Button(action: onExplore) {
            VStack(alignment: .leading, spacing: 10) {
                // Top Header: Icon, Category Name & Arrow
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(subtitleText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor.opacity(0.8))
                }
                
                Spacer(minLength: 4)
                
                // Bottom Readout: Size & Items Count
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(ByteFormatter.string(from: displayBytes))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(displayBytes > 0 ? .primary : .secondary)
                        
                        Text(category == .largeFiles ? "\(items.count) files found" : "\(eligibleItems.count) eligible items")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if displayBytes > 0 {
                        Text("Inspect")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.12))
                            .foregroundColor(accentColor)
                            .cornerRadius(4)
                    }
                }
                
                // Visual Mini Capacity Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(NSColor.separatorColor).opacity(0.25))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(displayBytes > 0 ? accentColor : Color.clear)
                            .frame(width: max(4, geo.size.width * CGFloat(relativeShare)), height: 4)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: relativeShare)
                    }
                }
                .frame(height: 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor).opacity(0.45), lineWidth: 1)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .interactiveCard(
            scale: 1.018,
            hoverBackground: accentColor.opacity(0.06),
            hoverBorder: accentColor.opacity(0.4),
            cornerRadius: 10,
            pointer: true
        )
    }
}
