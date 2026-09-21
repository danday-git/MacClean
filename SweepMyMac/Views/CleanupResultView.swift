import SwiftUI

struct CleanupResultView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var isPresented: Bool
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        let isID = languageManager.language == .indonesian
        let results = viewModel.cleanupResults
        let successCount = results.filter { $0.status == .moved }.count
        let failureCount = results.filter { $0.status != .moved }.count
        let bytesMoved = results.filter { $0.status == .moved }.reduce(0) { $0 + $1.sourceItem.size }
        let beforeAfter = viewModel.latestCleanupResult
        
        VStack(spacing: 16) {
            // 1. Success / Status Icon & Title
            VStack(spacing: 6) {
                Image(systemName: failureCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(failureCount == 0 ? Color.mcEmerald : Color.mcCoral)
                    .padding(.top, 4)
                
                Text(failureCount == 0 ? (isID ? "Pembersihan Berhasil" : "Cleanup Successful") : (isID ? "Pembersihan Sebagian Selesai" : "Cleanup Partially Completed"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.mcOnSurface)
                
                Text(isID ? "\(ByteFormatter.string(from: bytesMoved)) dipindahkan ke Tempat Sampah" : "\(ByteFormatter.string(from: bytesMoved)) moved to macOS Trash")
                    .font(.headline)
                    .foregroundColor(Color.mcPrimary)
                
                let cleanedText = isID ?
                    "\(successCount) item berhasil dibersihkan\(failureCount > 0 ? " • \(failureCount) item dilewati" : "")." :
                    "\(successCount) item\(successCount == 1 ? "" : "s") cleaned successfully\(failureCount > 0 ? " • \(failureCount) item(s) skipped" : "")."
                Text(cleanedText)
                    .font(.subheadline)
                    .foregroundColor(Color.mcOnSurfaceVariant)
            }
            
            // 2. Before & After Storage Comparison Card
            if let ba = beforeAfter {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(Color.mcCyan)
                            .font(.caption)
                        Text(isID ? "Dampak Penyimpanan • Sebelum & Sesudah" : "Storage Impact • Before & After")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.mcOnSurfaceVariant)
                        Spacer()
                    }
                    
                    HStack(spacing: 0) {
                        // BEFORE Column
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isID ? "SEBELUM" : "BEFORE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.mcOutline)
                            
                            HStack(spacing: 4) {
                                Text(isID ? "Bebas:" : "Free:")
                                    .font(.caption2)
                                    .foregroundColor(Color.mcOutline)
                                Text(ByteFormatter.string(from: ba.beforeFreeBytes))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.mcOnSurface)
                            }
                            
                            HStack(spacing: 4) {
                                Text(isID ? "Terpakai:" : "Used:")
                                    .font(.caption2)
                                    .foregroundColor(Color.mcOutline)
                                Text(ByteFormatter.string(from: ba.beforeUsedBytes))
                                    .font(.caption)
                                    .foregroundColor(Color.mcOnSurfaceVariant)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // TRANSITION Indicator
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.mcEmerald)
                            
                            Text("+\(ByteFormatter.string(from: ba.freeSpaceGain))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mcEmerald.opacity(0.14))
                                .foregroundColor(Color.mcEmerald)
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 8)
                        
                        // AFTER Column
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isID ? "SESUDAH" : "AFTER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.mcOutline)
                            
                            HStack(spacing: 4) {
                                Text(isID ? "Bebas:" : "Free:")
                                    .font(.caption2)
                                    .foregroundColor(Color.mcOutline)
                                Text(ByteFormatter.string(from: ba.effectiveAfterFreeBytes))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.mcEmerald)
                            }
                            
                            HStack(spacing: 4) {
                                Text(isID ? "Terpakai:" : "Used:")
                                    .font(.caption2)
                                    .foregroundColor(Color.mcOutline)
                                Text(ByteFormatter.string(from: ba.effectiveAfterUsedBytes))
                                    .font(.caption)
                                    .foregroundColor(Color.mcOnSurfaceVariant)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Category breakdown pills
                    if !ba.categoryStats.isEmpty {
                        Divider()
                            .padding(.vertical, 2)
                        
                        HStack(spacing: 8) {
                            ForEach(ba.categoryStats) { stat in
                                HStack(spacing: 4) {
                                    Text(stat.category.displayName(for: languageManager.language))
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.mcOutline)
                                    Text(ByteFormatter.string(from: stat.bytes))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color.mcOnSurface)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mcSurfaceHighest)
                                .cornerRadius(4)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(14)
                .background(Color.mcSurfaceHigh)
                .cornerRadius(10)
            }
            
            // 3. Failures List (if any)
            if failureCount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isID ? "Kendala yang dihadapi saat pembersihan:" : "Issues encountered during cleanup:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.mcCoral)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(results.filter { $0.status != .moved }, id: \.sourceItem.id) { result in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.sourceItem.path.path)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    Text("Reason: \(String(describing: result.status))")
                                        .font(.system(size: 9))
                                        .foregroundColor(Color.mcOutline)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.mcCoral.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxHeight: 90)
                }
                .padding(.horizontal, 4)
            }
            
            // 4. macOS Trash Reassurance Note
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "trash.fill")
                    .foregroundColor(Color.mcCoral)
                    .font(.caption)
                    .padding(.top, 1)
                
                Text(isID ? "Berkas telah dipindahkan secara aman ke Tempat Sampah macOS. Anda dapat memeriksa atau memulihkannya kapan saja. Untuk mengosongkan ruang APFS secara fisik, kosongkan Tempat Sampah di Finder." : "Files were safely moved to your macOS Trash. You can inspect or restore them at any time. To permanently reclaim physical APFS storage, empty the Trash in Finder.")
                    .font(.caption2)
                    .foregroundColor(Color.mcOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(10)
            .background(Color.mcSurfaceHigh.opacity(0.6))
            .cornerRadius(8)
            
            // 5. Actions
            HStack(spacing: 14) {
                Button(action: {
                    viewModel.openTrashInFinder()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text(isID ? "Buka Tempat Sampah di Finder" : "Open Trash in Finder")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(isID ? "Selesai" : "Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.mcCyan)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 480)
    }
}
