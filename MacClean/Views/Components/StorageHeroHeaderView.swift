import SwiftUI

struct StorageHeroHeaderView: View {
    let summary: StorageSummary
    let reclaimableBytes: Int64
    
    private var usedFraction: Double {
        guard summary.totalSpace > 0 else { return 0 }
        return min(1.0, max(0.0, Double(summary.usedSpace) / Double(summary.totalSpace)))
    }
    
    private var reclaimableFraction: Double {
        guard summary.totalSpace > 0 else { return 0 }
        return min(usedFraction, max(0.0, Double(reclaimableBytes) / Double(summary.totalSpace)))
    }
    
    private var baseUsedFraction: Double {
        max(0.0, usedFraction - reclaimableFraction)
    }
    
    private var usedPercentage: Int {
        Int(round(usedFraction * 100))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Drive Name & Storage Numbers
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive.fill")
                        .foregroundColor(.blue)
                        .font(.body)
                    Text("Macintosh HD")
                        .font(.headline)
                    Text("APFS")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(ByteFormatter.string(from: summary.usedSpace))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text("used of \(ByteFormatter.string(from: summary.totalSpace))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(ByteFormatter.string(from: summary.freeSpace)) Free")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                    
                    if reclaimableBytes > 0 {
                        Text("\(ByteFormatter.string(from: reclaimableBytes)) Reclaimable")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                }
            }
            
            // Fluid Segmented Storage Bar
            GeometryReader { geo in
                let totalW = geo.size.width
                let baseW = max(0, totalW * CGFloat(baseUsedFraction))
                let reclaimW = max(0, totalW * CGFloat(reclaimableFraction))
                
                ZStack(alignment: .leading) {
                    // Background Track (Available Space)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.separatorColor).opacity(0.3))
                        .frame(height: 12)
                    
                    HStack(spacing: 2) {
                        if baseW > 2 {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
                                .frame(width: baseW, height: 12)
                        }
                        
                        if reclaimW > 2 {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.orange)
                                .frame(width: reclaimW, height: 12)
                                .shadow(color: Color.orange.opacity(0.5), radius: 3, x: 0, y: 0)
                        }
                    }
                }
            }
            .frame(height: 12)
            
            // Bottom Legend
            HStack(spacing: 14) {
                legendItem(title: "Used", bytes: summary.usedSpace - reclaimableBytes, color: .blue)
                if reclaimableBytes > 0 {
                    legendItem(title: "Safe to Clean", bytes: reclaimableBytes, color: .orange)
                }
                legendItem(title: "Available", bytes: summary.freeSpace, color: .green)
                
                Spacer()
                
                Text("\(usedPercentage)% used")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor).opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    private func legendItem(title: String, bytes: Int64, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(ByteFormatter.string(from: bytes))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}
