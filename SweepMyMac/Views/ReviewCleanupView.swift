import SwiftUI

struct ReviewCleanupView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var selection: CleanupSelectionViewModel
    @Binding var isPresented: Bool
    
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var cleanupPlan: CleanupPlan?
    @State private var isValidating = true
    @State private var showingConfirmation = false
    @State private var selectedExplanationItem: ScanResultItem?
    
    var body: some View {
        let isID = languageManager.language == .indonesian
        return VStack(spacing: 0) {
            Text(isID ? "Tinjau Pembersihan" : "Review Cleanup")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.mcOnSurface)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            Text(isID ? "Item yang dipilih:" : "Selected items:")
                .font(.headline)
                .foregroundColor(Color.mcOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            
            if isValidating {
                Spacer()
                ProgressView(isID ? "Memvalidasi pilihan..." : "Validating selection...")
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
                                                Text(isID ? "Aplikasi Terhapus" : "App Not Found")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.mcCoral.opacity(0.12))
                                            .foregroundColor(Color.mcCoral)
                                            .cornerRadius(4)
                                        }
                                        
                                        if let owner = item.ownerApplication {
                                            Text(isID ? "Aplikasi: \(owner)" : "App: \(owner)")
                                                .font(.system(size: 9, weight: .medium))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.mcCyan.opacity(0.1))
                                                .foregroundColor(Color.mcCyan)
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Text(item.path.path)
                                        .font(.caption2)
                                        .foregroundColor(Color.mcOutline)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(ByteFormatter.string(from: item.size))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.mcOnSurface)
                                    
                                    Button(action: {
                                        selectedExplanationItem = item
                                    }) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "info.circle")
                                            Text(isID ? "Mengapa?" : "Why?")
                                        }
                                        .font(.caption2)
                                        .foregroundColor(Color.mcCyan)
                                    }
                                    .buttonStyle(.borderless)
                                    .help(isID ? "Jelaskan mengapa item ini dapat dibersihkan" : "Explain why SweepMyMac can clean this item")
                                }
                            }
                            .padding(12)
                            .background(Color.mcSurfaceHigh)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if !plan.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(isID ? "Peringatan Validasi" : "Validation Warnings")
                                .font(.headline)
                                .foregroundColor(Color.mcCoral)
                            ForEach(0..<plan.warnings.count, id: \.self) { i in
                                Text("• \(warningDescription(plan.warnings[i], isID: isID))")
                                    .font(.caption)
                                    .foregroundColor(Color.mcCoral)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.mcCoral.opacity(0.1))
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
                        Text(isID ? "\(plan.items.count) item" : "\(plan.items.count) items")
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
                                Text(isID ? "Sisa Aplikasi:" : "App Leftovers:")
                                    .font(.caption2)
                                    .foregroundColor(Color.mcOnSurfaceVariant)
                                Text(ByteFormatter.string(from: leftoversBytes))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.mcOnSurface)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mcSurfaceHigh)
                            .cornerRadius(4)
                        }
                        if cachesBytes > 0 {
                            HStack(spacing: 3) {
                                Text(isID ? "Cache Aplikasi:" : "App Caches:")
                                    .font(.caption2)
                                    .foregroundColor(Color.mcOnSurfaceVariant)
                                Text(ByteFormatter.string(from: cachesBytes))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.mcOnSurface)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mcSurfaceHigh)
                            .cornerRadius(4)
                        }
                        if devBytes > 0 {
                            HStack(spacing: 3) {
                                Text(isID ? "Cache Dev:" : "Dev Caches:")
                                    .font(.caption2)
                                    .foregroundColor(Color.mcOnSurfaceVariant)
                                Text(ByteFormatter.string(from: devBytes))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.mcOnSurface)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mcSurfaceHigh)
                            .cornerRadius(4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(isID ? "Berkas ini akan dipindahkan ke Trash secara aman." : "These files will be safely moved to macOS Trash.")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.mcSurfaceHighest)
            }
            
            if !viewModel.isCleaningUp && viewModel.cleanupResults.isEmpty {
                HStack(spacing: 16) {
                    Button(isID ? "Kembali" : "Back") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                    
                    Button(isID ? "Pindahkan ke Tong Sampah" : "Move to Trash") {
                        showingConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.mcCyan)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isValidating || (cleanupPlan?.items.isEmpty ?? true) || !(cleanupPlan?.warnings.isEmpty ?? true))
                    .alert(isPresented: $showingConfirmation) {
                        let alertTitle = isID ? "Pindahkan ke Tong Sampah?" : "Move to Trash?"
                        let alertMsg = isID ?
                            "\(cleanupPlan?.items.count ?? 0) item (\(ByteFormatter.string(from: cleanupPlan?.totalSize ?? 0)))\n\nBerkas ini akan dipindahkan ke macOS Trash. SweepMyMac tidak akan menghapusnya secara permanen.\n\nAnda dapat meninjau atau memulihkannya nanti di Trash." :
                            "\(cleanupPlan?.items.count ?? 0) items (\(ByteFormatter.string(from: cleanupPlan?.totalSize ?? 0)))\n\nThese files will be moved to macOS Trash. SweepMyMac will not permanently delete them.\n\nYou can review or restore them later from the Trash."
                        return Alert(
                            title: Text(alertTitle),
                            message: Text(alertMsg),
                            primaryButton: .destructive(Text(isID ? "Pindahkan ke Trash" : "Move to Trash")) {
                                if let plan = cleanupPlan {
                                    Task {
                                        await viewModel.performCleanup(plan: plan)
                                    }
                                }
                            },
                            secondaryButton: .cancel(Text(isID ? "Batal" : "Cancel"))
                        )
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(width: 500, height: 600)
        .background(Color.mcSurfaceContainer)
        .overlay {
            if viewModel.isCleaningUp {
                Color.mcSurfaceContainer
                CleanupProgressView(viewModel: viewModel)
            } else if !viewModel.cleanupResults.isEmpty {
                Color.mcSurfaceContainer
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
    
    private func warningDescription(_ warning: CleanupWarning, isID: Bool) -> String {
        switch warning {
        case .protectedPath:
            return isID ? "Jalur sistem yang terlindungi dipilih." : "A protected path was selected."
        case .unknownItem:
            return isID ? "Item yang tidak dikenal atau belum diverifikasi dipilih." : "An unknown or unverified item was selected."
        case .pathOutsideHomeDirectory:
            return isID ? "Item di luar direktori beranda dipilih." : "An item outside your home directory was selected."
        case .itemDisappeared:
            return isID ? "Item sudah tidak ditemukan di disk penyimpanan." : "An item no longer exists on disk."
        case .permissionDenied:
            return isID ? "Izin akses macOS ditolak untuk item ini." : "Permission denied for an item."
        case .symbolicLinkDetected:
            return isID ? "Tautan simbolik (symlink) terdeteksi dan dilewati demi keamanan." : "A symbolic link was detected and rejected for safety."
        case .pathTraversalDetected:
            return isID ? "Indikasi path traversal terdeteksi dan dibatalkan." : "A path traversal attempt was detected."
        case .notRegularFileOrDirectory:
            return isID ? "Tipe berkas tidak didukung (mis. socket atau perangkat) ditolak." : "An unsupported file type (e.g. socket or device) was rejected."
        }
    }
}
