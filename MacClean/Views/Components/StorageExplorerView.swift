import SwiftUI

struct StorageExplorerView: View {
    let breakdown: StorageBreakdown
    let topConsumers: [TopSpaceConsumer]
    let onRevealInFinder: (URL) -> Void
    
    @State private var expandedConsumerIDs: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Storage Explorer")
                        .font(.headline)
                    Text("Composition breakdown of used disk space")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Total Used: \(ByteFormatter.string(from: breakdown.totalUsedBytes))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            
            // Segmented Storage Bar
            GeometryReader { geometry in
                let total = max(1, CGFloat(breakdown.totalUsedBytes))
                let appW = max(2, geometry.size.width * CGFloat(breakdown.applicationsBytes) / total)
                let filesW = max(2, geometry.size.width * CGFloat(breakdown.userFilesBytes) / total)
                let dataW = max(2, geometry.size.width * CGFloat(breakdown.appDataBytes) / total)
                let cachesW = max(2, geometry.size.width * CGFloat(breakdown.cachesBytes) / total)
                let devW = max(2, geometry.size.width * CGFloat(breakdown.developerDataBytes) / total)
                let sysW = max(2, geometry.size.width * CGFloat(breakdown.systemAndOtherBytes) / total)
                
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: appW)
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: filesW)
                    Rectangle()
                        .fill(Color.teal)
                        .frame(width: dataW)
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: cachesW)
                    Rectangle()
                        .fill(Color.indigo)
                        .frame(width: devW)
                    Rectangle()
                        .fill(Color.gray.opacity(0.7))
                        .frame(width: sysW)
                }
                .frame(height: 18)
                .cornerRadius(9)
                .clipped()
            }
            .frame(height: 18)
            
            // Legend
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                legendItem(title: "Applications", bytes: breakdown.applicationsBytes, color: .blue)
                legendItem(title: "Your Files", bytes: breakdown.userFilesBytes, color: .purple)
                legendItem(title: "App Data", bytes: breakdown.appDataBytes, color: .teal)
                legendItem(title: "Caches", bytes: breakdown.cachesBytes, color: .orange)
                legendItem(title: "Developer Data", bytes: breakdown.developerDataBytes, color: .indigo)
                legendItem(title: "System & Other", bytes: breakdown.systemAndOtherBytes, color: .gray)
            }
            .padding(.top, 2)
            
            // Honest Breakdown Estimate Disclaimer
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                    .padding(.top, 1)
                Text("Storage breakdown is a categorized estimate. macOS system storage, APFS snapshots, purgeable files, and virtual memory are not individually itemized.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(6)
            
            Divider()
                .padding(.vertical, 4)
            
            // Top Space Consumers Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .foregroundColor(.secondary)
                    Text("Top Space Consumers")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Why is my Mac full?")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if topConsumers.isEmpty {
                    Text("Scan storage to inspect top space consumers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 6) {
                        ForEach(topConsumers) { consumer in
                            consumerRow(consumer)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(10)
    }
    
    private func legendItem(title: String, bytes: Int64, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(ByteFormatter.string(from: bytes))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        .cornerRadius(6)
        .interactiveCard(scale: 1.02, hoverBackground: color.opacity(0.12), hoverBorder: color.opacity(0.35), cornerRadius: 6, pointer: false)
    }
    
    @ViewBuilder
    private func consumerRow(_ consumer: TopSpaceConsumer) -> some View {
        let isExpanded = expandedConsumerIDs.contains(consumer.id)
        
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: iconForCategory(consumer.categoryDescription))
                    .foregroundColor(colorForCategory(consumer.categoryDescription))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(consumer.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text(consumer.categoryDescription)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(colorForCategory(consumer.categoryDescription).opacity(0.12))
                            .foregroundColor(colorForCategory(consumer.categoryDescription))
                            .cornerRadius(4)
                    }
                    
                    Text(consumer.path.path)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                Text(ByteFormatter.string(from: consumer.size))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                
                Button(action: {
                    onRevealInFinder(consumer.path)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Finder")
                    }
                    .font(.caption2)
                }
                .buttonStyle(.borderless)
                .pointerCursor()
                .help("Reveal in Finder")
                
                if !consumer.subItems.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            if isExpanded {
                                expandedConsumerIDs.remove(consumer.id)
                            } else {
                                expandedConsumerIDs.insert(consumer.id)
                            }
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                    .help(isExpanded ? "Collapse sub-items" : "Drill down")
                }
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            .interactiveRow(cornerRadius: 6)
            
            // Drill-down sub-items
            if isExpanded && !consumer.subItems.isEmpty {
                VStack(spacing: 4) {
                    ForEach(consumer.subItems) { sub in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(sub.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                            
                            Text("(\(sub.categoryDescription))")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(ByteFormatter.string(from: sub.size))
                                .font(.system(.caption2, design: .monospaced))
                            
                            Button(action: {
                                onRevealInFinder(sub.path)
                            }) {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption2)
                            }
                            .buttonStyle(.borderless)
                            .help("Reveal sub-item in Finder")
                        }
                        .padding(.leading, 28)
                        .padding(.trailing, 8)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func iconForCategory(_ cat: String) -> String {
        switch cat.lowercased() {
        case let c where c.contains("developer"): return "hammer.fill"
        case let c where c.contains("files"): return "folder.fill"
        case let c where c.contains("app data"): return "app.badge.fill"
        case let c where c.contains("caches"): return "bolt.shield.fill"
        case let c where c.contains("runtime"): return "gearshape.2.fill"
        case let c where c.contains("personal"): return "film.fill"
        default: return "folder.fill"
        }
    }
    
    private func colorForCategory(_ cat: String) -> Color {
        switch cat.lowercased() {
        case let c where c.contains("developer"): return .indigo
        case let c where c.contains("files") || c.contains("personal"): return .purple
        case let c where c.contains("app data"): return .teal
        case let c where c.contains("caches"): return .orange
        case let c where c.contains("runtime"): return .blue
        default: return .secondary
        }
    }
}
