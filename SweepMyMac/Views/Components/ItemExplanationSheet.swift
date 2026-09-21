import SwiftUI

struct ItemExplanationSheet: View {
    let item: ScanResultItem
    let onRevealInFinder: () -> Void
    let onDismiss: () -> Void
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        let isID = languageManager.language == .indonesian
        return VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: item.confidenceTier.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(item.confidenceTier.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.whyDialogTitle(for: languageManager.language))
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(item.confidenceTier.badgeLabel(for: languageManager.language))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.confidenceTier.color.opacity(0.12))
                        .foregroundColor(item.confidenceTier.color)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.mcOutline)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            // Item Information Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(ByteFormatter.string(from: item.size))
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.bold)
                }
                
                Text(item.path.path)
                    .font(.caption2)
                    .foregroundColor(Color.mcOutline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack {
                    Spacer()
                    Button(action: onRevealInFinder) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.forward.app")
                            Text(isID ? "Buka di Finder" : "Reveal in Finder")
                        }
                        .font(.caption2)
                        .foregroundColor(Color.mcCyan)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(12)
            .background(Color.mcSurfaceHigh)
            .cornerRadius(8)
            
            // Detailed Explanations
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isID ? "Apa ini?" : "What is this?")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.mcOnSurface)
                    
                    Text(item.humanExplanationText(for: languageManager.language))
                        .font(.callout)
                        .foregroundColor(Color.mcOnSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isID ? "Detail Aksi & Keamanan" : "Action & Safety Details")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.mcOnSurface)
                    
                    Text(item.consequenceExplanationText(for: languageManager.language))
                        .font(.callout)
                        .foregroundColor(Color.mcOnSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Reassurance Badge
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(Color.mcCyan)
                    .font(.caption)
                    .padding(.top, 1)
                
                Text(isID ? "Jaminan Keamanan: SweepMyMac tidak pernah menghapus berkas secara permanen. Semua pembersihan yang disetujui hanya memindahkan berkas ke macOS Trash, yang dapat ditinjau atau dipulihkan kembali." : "Safety Guarantee: SweepMyMac never permanently deletes files. All approved cleanups only move files to macOS Trash, which can be reviewed or restored at any time.")
                    .font(.caption2)
                    .foregroundColor(Color.mcOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(Color.mcCyan.opacity(0.12))
            .cornerRadius(6)
            
            // Bottom Action
            HStack {
                Spacer()
                Button(isID ? "Selesai" : "Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.mcCyan)
                .controlSize(.regular)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
