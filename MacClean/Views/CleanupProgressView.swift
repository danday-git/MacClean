import SwiftUI

struct CleanupProgressView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        let isID = languageManager.language == .indonesian
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .padding(.bottom, 8)
            
            Text(isID ? "Memindahkan item yang dipilih ke Tempat Sampah..." : "Moving selected items to Trash...")
                .font(.headline)
                .foregroundColor(Color.mcOnSurface)
            
            VStack(spacing: 8) {
                Text(isID ? "\(viewModel.cleanupProgress.current) / \(viewModel.cleanupProgress.total) selesai" : "\(viewModel.cleanupProgress.current) / \(viewModel.cleanupProgress.total) completed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.mcOnSurfaceVariant)
                
                // For simplicity, we just show the progress ratio as bytes moved is computed at the end
                ProgressView(value: Double(viewModel.cleanupProgress.current), total: Double(max(1, viewModel.cleanupProgress.total)))
                    .frame(width: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
