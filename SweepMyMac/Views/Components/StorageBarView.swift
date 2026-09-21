import SwiftUI

struct StorageBarView: View {
    let summary: StorageSummary
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Storage")
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    let usedRatio = CGFloat(summary.usedSpace) / CGFloat(summary.totalSpace)
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: max(0, geometry.size.width * usedRatio), height: 20)
                        .cornerRadius(10)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("\(viewModel.sizeString(for: summary.usedSpace)) Used")
                Spacer()
                Text("\(viewModel.sizeString(for: summary.freeSpace)) Free")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}
