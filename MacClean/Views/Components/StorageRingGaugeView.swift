import SwiftUI

struct StorageRingGaugeView: View {
    let summary: StorageSummary
    let reclaimableBytes: Int64
    let isScanning: Bool
    let scanningStatus: String
    let scanProgressLog: [String]
    let onScan: () -> Void
    let onCancelScan: () -> Void
    
    // Computed fraction (0.0 to 1.0)
    private var usedFraction: Double {
        guard summary.totalSpace > 0 else { return 0 }
        return min(1.0, max(0.0, Double(summary.usedSpace) / Double(summary.totalSpace)))
    }
    
    private var reclaimableFraction: Double {
        guard summary.totalSpace > 0 else { return 0 }
        return min(usedFraction, max(0.0, Double(reclaimableBytes) / Double(summary.totalSpace)))
    }
    
    private var usedPercentage: Int {
        Int(round(usedFraction * 100))
    }
    
    var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundColor(.blue)
                    .font(.subheadline)
                Text("Storage Pulse")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("Macintosh HD")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            // Circular Ring Meter
            ZStack {
                // Background Track
                Circle()
                    .stroke(
                        Color(NSColor.separatorColor).opacity(0.35),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 175, height: 175)
                
                // Used Space Arc
                Circle()
                    .trim(from: 0, to: CGFloat(usedFraction))
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 175, height: 175)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: usedFraction)
                
                // Potential Reclaimable Arc (Glowing Orange Slice)
                if reclaimableFraction > 0.005 {
                    Circle()
                        .trim(
                            from: CGFloat(max(0, usedFraction - reclaimableFraction)),
                            to: CGFloat(usedFraction)
                        )
                        .stroke(
                            Color.orange,
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .frame(width: 175, height: 175)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.orange.opacity(0.5), radius: 4, x: 0, y: 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: reclaimableFraction)
                }
                
                // Center Readout
                VStack(spacing: 3) {
                    Text("\(usedPercentage)%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Disk Used")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    // Available pill
                    Text("\(ByteFormatter.string(from: summary.freeSpace)) Free")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 6)
            
            // Storage Statistics Grid
            VStack(spacing: 8) {
                HStack {
                    statRow(
                        title: "Used Space",
                        value: ByteFormatter.string(from: summary.usedSpace),
                        dotColor: .blue
                    )
                    Spacer()
                    statRow(
                        title: "Capacity",
                        value: ByteFormatter.string(from: summary.totalSpace),
                        dotColor: .secondary
                    )
                }
                
                Divider()
                
                HStack {
                    statRow(
                        title: "Available",
                        value: ByteFormatter.string(from: summary.freeSpace),
                        dotColor: .green
                    )
                    Spacer()
                    statRow(
                        title: "Reclaimable",
                        value: reclaimableBytes > 0 ? ByteFormatter.string(from: reclaimableBytes) : "0 B",
                        dotColor: .orange
                    )
                }
            }
            .padding(10)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
            .cornerRadius(8)
            
            // System & Safety Badges
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.green)
                        .font(.caption2)
                    Text("100% Trash Safe")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "apple.logo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("APFS Container")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            // Primary Scan CTA Button or Scanning Status
            if isScanning {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(scanningStatus)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Button("Cancel") {
                            onCancelScan()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if let lastLog = scanProgressLog.last, !lastLog.isEmpty {
                        Text(lastLog)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            } else {
                Button(action: onScan) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.headline)
                        Text("Scan Storage")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)
                .pointerCursor()
            }
        }
        .padding(18)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private func statRow(title: String, value: String, dotColor: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}
