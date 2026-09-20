import SwiftUI

struct StorageHeroHeaderView: View {
    let summary: StorageSummary
    let breakdown: StorageBreakdown?
    let reclaimableBytes: Int64
    
    @State private var isPulsing = false
    
    private var totalBytes: Int64 {
        max(1, summary.totalSpace)
    }
    
    private var usedFraction: Double {
        min(1.0, max(0.0, Double(summary.usedSpace) / Double(totalBytes)))
    }
    
    private var usedPercentage: Double {
        (Double(summary.usedSpace) / Double(totalBytes)) * 100
    }
    
    // Proportional breakdown fractions of total disk space
    private var appsFraction: Double {
        guard let b = breakdown else { return usedFraction * 0.45 }
        return Double(b.applicationsBytes) / Double(totalBytes)
    }
    
    private var devFraction: Double {
        guard let b = breakdown else { return usedFraction * 0.20 }
        return Double(b.developerDataBytes) / Double(totalBytes)
    }
    
    private var systemFraction: Double {
        guard let b = breakdown else { return usedFraction * 0.25 }
        return Double(b.systemAndOtherBytes + b.userFilesBytes + b.appDataBytes) / Double(totalBytes)
    }
    
    private var cacheFraction: Double {
        guard let b = breakdown else { return usedFraction * 0.10 }
        return Double(b.cachesBytes) / Double(totalBytes)
    }
    
    private var freeFraction: Double {
        Double(summary.freeSpace) / Double(totalBytes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // MARK: - Header Telemetry Row
            ViewThatFits(in: .horizontal) {
                // Wide Layout
                HStack(alignment: .center, spacing: 14) {
                    driveIdentityView
                    Spacer()
                    telemetryBadgesView
                }
                
                // Compact Layout
                VStack(alignment: .leading, spacing: 12) {
                    driveIdentityView
                    telemetryBadgesView
                }
            }
            
            // MARK: - Slim Segmented Visual Bar
            segmentedStorageBar
            
            // MARK: - Color Legend Breakdown Pills
            colorLegendView
        }
        .padding(20)
        .background(Color.mcSurfaceContainer.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
    
    // MARK: - Drive Identity Subview
    private var driveIdentityView: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mcSurfaceHigh)
                    .frame(width: 42, height: 42)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mcOutlineVariant.opacity(0.35), lineWidth: 1)
                    )
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.mcCyan)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Macintosh HD")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.mcOnSurface)
                    
                    Text("APFS Container disk3s1")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.mcSurfaceHighest)
                        .foregroundColor(Color.mcOutline)
                        .cornerRadius(4)
                }
                
                Text("Internal Solid State Drive • 98% Kesehatan SSD (36°C)")
                    .font(.system(size: 12))
                    .foregroundColor(Color.mcOnSurfaceVariant)
            }
        }
    }
    
    // MARK: - Telemetry Badges Subview
    private var telemetryBadgesView: some View {
        HStack(spacing: 8) {
            // TERPAKAI
            HStack(spacing: 4) {
                Text("TERPAKAI:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.mcOutline)
                Text(ByteFormatter.string(from: summary.usedSpace))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.mcOnSurface)
                Text("/ \(ByteFormatter.string(from: summary.totalSpace)) (\(String(format: "%.1f", usedPercentage))%)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.mcOnSurfaceVariant)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.mcSurfaceLowest.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(10)
            
            // BEBAS (Pulsing Emerald)
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.mcEmerald)
                    .frame(width: 7, height: 7)
                    .scaleEffect(isPulsing ? 1.25 : 0.85)
                    .opacity(isPulsing ? 1.0 : 0.6)
                Text("\(ByteFormatter.string(from: summary.freeSpace)) Bebas")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.mcEmerald)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Color.mcEmerald.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.mcEmerald.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(10)
            
            // SMART Normal
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color.mcEmerald)
                Text("SMART Normal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.mcOnSurface)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color.mcSurfaceHigh.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.mcOutlineVariant.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }
    
    // MARK: - Slim Segmented Visual Bar
    private var segmentedStorageBar: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let appsW = max(3, totalW * CGFloat(appsFraction))
            let devW = max(3, totalW * CGFloat(devFraction))
            let sysW = max(3, totalW * CGFloat(systemFraction))
            let cacheW = max(3, totalW * CGFloat(cacheFraction))
            let freeW = max(3, totalW - appsW - devW - sysW - cacheW)
            
            HStack(spacing: 2) {
                // 1. Aplikasi
                Rectangle()
                    .fill(Color.mcCyanGlow)
                    .frame(width: appsW)
                    .help("Aplikasi: \(ByteFormatter.string(from: breakdown?.applicationsBytes ?? 0))")
                
                // 2. Data Pengembang
                Rectangle()
                    .fill(Color.mcCyan)
                    .frame(width: devW)
                    .help("Data Pengembang: \(ByteFormatter.string(from: breakdown?.developerDataBytes ?? 0))")
                
                // 3. Sistem & macOS
                Rectangle()
                    .fill(Color.mcViolet)
                    .frame(width: sysW)
                    .help("Sistem & macOS: \(ByteFormatter.string(from: (breakdown?.systemAndOtherBytes ?? 0) + (breakdown?.userFilesBytes ?? 0)))")
                
                // 4. Cache & Log
                Rectangle()
                    .fill(Color.mcCoral)
                    .frame(width: cacheW)
                    .help("Cache & Log: \(ByteFormatter.string(from: breakdown?.cachesBytes ?? 0))")
                
                // 5. Bebas
                Rectangle()
                    .fill(Color.mcSurfaceVariant.opacity(0.45))
                    .frame(width: freeW)
                    .help("Bebas: \(ByteFormatter.string(from: summary.freeSpace))")
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
            )
        }
        .frame(height: 14)
    }
    
    // MARK: - Color Legend Breakdown Pills
    private var colorLegendView: some View {
        ViewThatFits(in: .horizontal) {
            // Single row
            HStack(spacing: 16) {
                legendItem(title: "Aplikasi", bytes: breakdown?.applicationsBytes ?? Int64(Double(summary.usedSpace) * 0.45), color: Color.mcCyanGlow)
                legendItem(title: "Data Pengembang", bytes: breakdown?.developerDataBytes ?? Int64(Double(summary.usedSpace) * 0.20), color: Color.mcCyan)
                legendItem(title: "Sistem & macOS", bytes: (breakdown?.systemAndOtherBytes ?? 0) + (breakdown?.userFilesBytes ?? Int64(Double(summary.usedSpace) * 0.25)), color: Color.mcViolet)
                legendItem(title: "Cache & Log", bytes: breakdown?.cachesBytes ?? Int64(Double(summary.usedSpace) * 0.10), color: Color.mcCoral)
                legendItem(title: "Bebas", bytes: summary.freeSpace, color: Color.mcEmerald)
            }
            
            // Wrapped 2 rows
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 14) {
                    legendItem(title: "Aplikasi", bytes: breakdown?.applicationsBytes ?? Int64(Double(summary.usedSpace) * 0.45), color: Color.mcCyanGlow)
                    legendItem(title: "Data Pengembang", bytes: breakdown?.developerDataBytes ?? Int64(Double(summary.usedSpace) * 0.20), color: Color.mcCyan)
                    legendItem(title: "Sistem & macOS", bytes: (breakdown?.systemAndOtherBytes ?? 0) + (breakdown?.userFilesBytes ?? Int64(Double(summary.usedSpace) * 0.25)), color: Color.mcViolet)
                }
                HStack(spacing: 14) {
                    legendItem(title: "Cache & Log", bytes: breakdown?.cachesBytes ?? Int64(Double(summary.usedSpace) * 0.10), color: Color.mcCoral)
                    legendItem(title: "Bebas", bytes: summary.freeSpace, color: Color.mcEmerald)
                }
            }
        }
    }
    
    private func legendItem(title: String, bytes: Int64, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Color.mcOutline)
            Text(ByteFormatter.string(from: bytes))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.mcOnSurface)
        }
    }
}
