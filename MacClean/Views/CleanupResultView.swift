import SwiftUI

struct CleanupResultView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
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
                    .foregroundColor(failureCount == 0 ? .green : .orange)
                    .padding(.top, 4)
                
                Text(failureCount == 0 ? "Cleanup Successful" : "Cleanup Partially Completed")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(ByteFormatter.string(from: bytesMoved)) moved to macOS Trash")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(successCount) item\(successCount == 1 ? "" : "s") cleaned successfully\(failureCount > 0 ? " • \(failureCount) item(s) skipped" : "").")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 2. Before & After Storage Comparison Card
            if let ba = beforeAfter {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Storage Impact • Before & After")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 0) {
                        // BEFORE Column
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BEFORE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text("Free:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(ByteFormatter.string(from: ba.beforeFreeBytes))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack(spacing: 4) {
                                Text("Used:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(ByteFormatter.string(from: ba.beforeUsedBytes))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // TRANSITION Indicator
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                            
                            Text("+\(ByteFormatter.string(from: ba.freeSpaceGain))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.14))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 8)
                        
                        // AFTER Column
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AFTER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text("Free:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(ByteFormatter.string(from: ba.effectiveAfterFreeBytes))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            HStack(spacing: 4) {
                                Text("Used:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(ByteFormatter.string(from: ba.effectiveAfterUsedBytes))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                                    Text(stat.category.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(ByteFormatter.string(from: stat.bytes))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(NSColor.separatorColor).opacity(0.15))
                                .cornerRadius(4)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            
            // 3. Failures List (if any)
            if failureCount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Issues encountered during cleanup:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
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
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08))
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
                    .foregroundColor(.orange)
                    .font(.caption)
                    .padding(.top, 1)
                
                Text("Files were safely moved to your macOS Trash. You can inspect or restore them at any time. To permanently reclaim physical APFS storage, empty the Trash in Finder.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
            
            // 5. Actions
            HStack(spacing: 14) {
                Button(action: {
                    viewModel.openTrashInFinder()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text("Open Trash in Finder")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 480)
    }
}
