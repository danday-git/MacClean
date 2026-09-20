import SwiftUI

struct CleanupProgressView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .padding(.bottom, 8)
            
            Text("Moving selected items to Trash...")
                .font(.headline)
            
            VStack(spacing: 8) {
                Text("\(viewModel.cleanupProgress.current) / \(viewModel.cleanupProgress.total) completed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // For simplicity, we just show the progress ratio as bytes moved is computed at the end
                ProgressView(value: Double(viewModel.cleanupProgress.current), total: Double(max(1, viewModel.cleanupProgress.total)))
                    .frame(width: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
