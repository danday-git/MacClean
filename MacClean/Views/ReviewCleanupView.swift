import SwiftUI

struct ReviewCleanupView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var selection: CleanupSelectionViewModel
    @Binding var isPresented: Bool
    
    @State private var cleanupPlan: CleanupPlan?
    @State private var isValidating = true
    @State private var showingConfirmation = false
    @State private var selectedExplanationItem: ScanResultItem?
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Review Cleanup")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            Text("You selected:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            
            if isValidating {
                Spacer()
                ProgressView("Validating selection...")
                Spacer()
            } else if let plan = cleanupPlan {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(plan.items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        if item.category == .appLeftovers {
                                            HStack(spacing: 3) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 8))
                                                Text("App Not Found")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.12))
                                            .foregroundColor(.red)
                                            .cornerRadius(4)
                                        }
                                        
                                        if let owner = item.ownerApplication {
                                            Text("App: \(owner)")
                                                .font(.system(size: 9, weight: .medium))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.1))
                                                .foregroundColor(.orange)
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Text(item.path.path)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(ByteFormatter.string(from: item.size))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Button(action: {
                                        selectedExplanationItem = item
                                    }) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "info.circle")
                                            Text("Why?")
                                        }
                                        .font(.caption2)
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Explain why MacClean can clean this item")
                                }
                            }
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if !plan.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Validation Warnings")
                                .font(.headline)
                                .foregroundColor(.red)
                            ForEach(0..<plan.warnings.count, id: \.self) { i in
                                Text("• \(warningDescription(plan.warnings[i]))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                }
                
                Divider()
                
                let leftoversBytes = plan.items.filter { $0.category == .appLeftovers }.reduce(0) { $0 + $1.size }
                let cachesBytes = plan.items.filter { $0.category == .caches }.reduce(0) { $0 + $1.size }
                let devBytes = plan.items.filter { $0.category == .developerData }.reduce(0) { $0 + $1.size }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("\(plan.items.count) items")
                            .font(.headline)
                        Spacer()
                        Text(ByteFormatter.string(from: plan.totalSize))
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    // 3 Bucket Breakdown Chips
                    HStack(spacing: 8) {
                        if leftoversBytes > 0 {
                            HStack(spacing: 3) {
                                Text("App Leftovers:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(ByteFormatter.string(from: leftoversBytes))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                        }
                        if cachesBytes > 0 {
                            HStack(spacing: 3) {
                                Text("Application Caches:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(ByteFormatter.string(from: cachesBytes))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                        }
                        if devBytes > 0 {
                            HStack(spacing: 3) {
                                Text("Developer Caches:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(ByteFormatter.string(from: devBytes))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("These files will be moved to Trash. They are not permanently deleted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(NSColor.windowBackgroundColor))
            }
            
            if !viewModel.isCleaningUp && viewModel.cleanupResults.isEmpty {
                HStack(spacing: 16) {
                    Button("Back") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Move to Trash") {
                        showingConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isValidating || (cleanupPlan?.items.isEmpty ?? true) || !(cleanupPlan?.warnings.isEmpty ?? true))
                    .alert(isPresented: $showingConfirmation) {
                        Alert(
                            title: Text("Move to Trash?"),
                            message: Text("\(cleanupPlan?.items.count ?? 0) items (\(ByteFormatter.string(from: cleanupPlan?.totalSize ?? 0)))\n\nThese files will be moved to the macOS Trash. They will not be permanently deleted by MacClean.\n\nYou can review or restore them in Trash afterward."),
                            primaryButton: .destructive(Text("Move to Trash")) {
                                if let plan = cleanupPlan {
                                    Task {
                                        await viewModel.performCleanup(plan: plan)
                                    }
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(width: 500, height: 600)
        .overlay {
            if viewModel.isCleaningUp {
                Color(NSColor.windowBackgroundColor)
                CleanupProgressView(viewModel: viewModel)
            } else if !viewModel.cleanupResults.isEmpty {
                Color(NSColor.windowBackgroundColor)
                CleanupResultView(viewModel: viewModel, isPresented: $isPresented)
            }
        }
        .sheet(item: $selectedExplanationItem) { item in
            ItemExplanationSheet(
                item: item,
                onRevealInFinder: {
                    viewModel.revealInFinder(url: item.path)
                },
                onDismiss: {
                    selectedExplanationItem = nil
                }
            )
        }
        .onAppear {
            viewModel.cleanupResults = []
            validateSelection()
        }
    }
    
    private func validateSelection() {
        isValidating = true
        
        Task {
            let validator = DefaultCleanupValidator()
            let allItems = viewModel.categoryItems.values.flatMap { $0 }
            let selectedScanItems = allItems.filter { selection.isSelected($0) }
            
            var validItems: [ScanResultItem] = []
            var warnings: [CleanupWarning] = []
            var totalSize: Int64 = 0
            
            for item in selectedScanItems {
                let result = validator.validate(item)
                switch result {
                case .valid:
                    validItems.append(item)
                    totalSize += item.size
                case .invalid(let reason):
                    if !warnings.contains(reason) {
                        warnings.append(reason)
                    }
                }
            }
            
            // Artificial delay for UX
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            self.cleanupPlan = CleanupPlan(items: validItems, totalSize: totalSize, warnings: warnings)
            self.isValidating = false
        }
    }
    
    private func warningDescription(_ warning: CleanupWarning) -> String {
        switch warning {
        case .protectedPath: return "A protected path was selected."
        case .unknownItem: return "An unknown or unverified item was selected."
        case .pathOutsideHomeDirectory: return "An item outside your home directory was selected."
        case .itemDisappeared: return "An item no longer exists on disk."
        case .permissionDenied: return "Permission denied for an item."
        case .symbolicLinkDetected: return "A symbolic link was detected and rejected for safety."
        case .pathTraversalDetected: return "A path traversal attempt was detected."
        case .notRegularFileOrDirectory: return "An unsupported file type (e.g. socket or device) was rejected."
        }
    }
}
