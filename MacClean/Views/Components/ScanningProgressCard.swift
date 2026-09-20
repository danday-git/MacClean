import SwiftUI

struct ScanningProgressCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Title, Elapsed Time, Cancel Button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Scanning your Mac…")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    Text("\(formattedElapsed(viewModel.scanElapsedTime)) elapsed · Inspecting storage safely")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    viewModel.cancelScan()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityLabel("Cancel scanning")
            }
            
            Divider()
            
            // Checklist Stages
            VStack(alignment: .leading, spacing: 8) {
                ForEach(ScanStage.allCases) { stage in
                    let status = viewModel.scanStages[stage] ?? .pending
                    stageRow(stage: stage, status: status)
                }
            }
            .padding(.vertical, 2)
            
            // Current Status sub-text
            if !viewModel.currentScanningStatus.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(viewModel.currentScanningStatus)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private func stageRow(stage: ScanStage, status: ScanStageStatus) -> some View {
        HStack(spacing: 10) {
            switch status {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.body)
                Text(stage.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                Text("Done")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            case .inProgress:
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.body)
                Text(stage.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                ProgressView()
                    .scaleEffect(0.6)
            case .pending:
                Image(systemName: "circle")
                    .foregroundColor(.secondary.opacity(0.6))
                    .font(.body)
                Text(stage.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            case .skipped:
                Image(systemName: "minus.circle")
                    .foregroundColor(.secondary)
                    .font(.body)
                Text(stage.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Skipped")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.body)
                Text(stage.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Unavailable")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func formattedElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
