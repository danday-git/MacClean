import SwiftUI

struct ItemExplanationSheet: View {
    let item: ScanResultItem
    let onRevealInFinder: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: item.confidenceTier.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(item.confidenceTier.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.whyDialogTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(item.confidenceTier.badgeLabel)
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
                        .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack {
                    Spacer()
                    Button(action: onRevealInFinder) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.forward.app")
                            Text("Reveal in Finder")
                        }
                        .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Detailed Explanations
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What is this?")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(item.humanExplanationText)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action & Safety Details")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(item.consequenceExplanationText)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Reassurance Badge
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .padding(.top, 1)
                
                Text("Safety Guarantee: MacClean never permanently deletes files. Any approved cleanup moves files to the macOS Trash, where they can be reviewed or restored.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(Color.blue.opacity(0.08))
            .cornerRadius(6)
            
            // Bottom Action
            HStack {
                Spacer()
                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
