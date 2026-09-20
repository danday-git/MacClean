import SwiftUI

struct RecommendedCleanupCard: View {
    let leftoverBytes: Int64
    let cacheBytes: Int64
    let devCacheBytes: Int64
    let totalReclaimableBytes: Int64
    let onReviewRecommended: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended Cleanup")
                        .font(.headline)
                    Text("Safe to reclaim right now · Verified caches & application leftovers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(ByteFormatter.string(from: totalReclaimableBytes))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
            
            Divider()
            
            // 3 Clean Buckets
            VStack(spacing: 10) {
                bucketRow(
                    icon: "trash.circle.fill",
                    color: .orange,
                    title: "App Leftovers",
                    subtitle: "Data from applications no longer installed",
                    bytes: leftoverBytes
                )
                
                bucketRow(
                    icon: "bolt.shield.fill",
                    color: .blue,
                    title: "Application Caches",
                    subtitle: "Regenerable cache files and temporary assets",
                    bytes: cacheBytes
                )
                
                bucketRow(
                    icon: "hammer.circle.fill",
                    color: .purple,
                    title: "Developer Caches",
                    subtitle: "Regenerable build caches and package data",
                    bytes: devCacheBytes
                )
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Bottom Action
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safe Action Guarantee")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Items will be moved to macOS Trash upon confirmation.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onReviewRecommended) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(totalReclaimableBytes > 0 ? "Review \(ByteFormatter.string(from: totalReclaimableBytes))" : "Review Recommended Cleanup")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.regular)
                .disabled(totalReclaimableBytes == 0)
                .pointerCursor()
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    private func bucketRow(icon: String, color: Color, title: String, subtitle: String, bytes: Int64) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(ByteFormatter.string(from: bytes))
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(bytes > 0 ? .primary : .secondary)
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        .cornerRadius(6)
        .interactiveRow(cornerRadius: 6)
    }
}
