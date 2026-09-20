import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingRecommendationModal = false
    @State private var showingDirectReview = false
    @State private var recommendedCount = 0
    @State private var recommendedBytes: Int64 = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dark Obsidian Canvas Background
            Color.mcBackground.ignoresSafeArea()
            
            // Subtle ambient backdrop glows
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.mcSurfaceVariant.opacity(0.35))
                        .frame(width: 500, height: 350)
                        .blur(radius: 80)
                        .offset(x: geo.size.width * 0.15, y: -40)
                    
                    Circle()
                        .fill(Color.mcSurfaceHigh.opacity(0.25))
                        .frame(width: 450, height: 350)
                        .blur(radius: 70)
                        .offset(x: geo.size.width * 0.65, y: 90)
                }
            }
            .allowsHitTesting(false)
            
            // Main Content Area
            VStack(spacing: 0) {
                topHeaderBar
                
                Divider()
                    .background(Color.mcOutlineVariant.opacity(0.25))
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 18) {
                        commonBanners
                        
                        if let summary = viewModel.summary {
                            // 1. Hero Storage Visualizer Card
                            StorageHeroHeaderView(
                                summary: summary,
                                breakdown: viewModel.storageBreakdown,
                                reclaimableBytes: viewModel.totalPotentialReclaimable
                            )
                            
                            // 2. 4-Column Category Cards Grid
                            categoryCardsGrid
                            
                            // 3. Interactive Clean Detail List & Inspection Table
                            FileInspectionTableView(
                                viewModel: viewModel,
                                selection: viewModel.selection
                            )
                        } else {
                            loadingStoragePlaceholder
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 110) // Ample clearance for floating action dock
                    .frame(maxWidth: 1200)
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Pinned Floating Bottom Action Dock
            floatingBottomActionDock
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
        }
        .frame(minWidth: 700, minHeight: 520)
        .sheet(isPresented: $showingRecommendationModal) {
            RecommendationExplanationView(
                count: recommendedCount,
                bytes: recommendedBytes,
                onConfirm: {
                    viewModel.selection.selectRecommended(in: viewModel.categoryItems)
                    viewModel.recalculateReclaimable()
                    showingRecommendationModal = false
                    showingDirectReview = true
                },
                onDismiss: {
                    showingRecommendationModal = false
                }
            )
        }
        .sheet(isPresented: $showingDirectReview) {
            ReviewCleanupView(
                viewModel: viewModel,
                selection: viewModel.selection,
                isPresented: $showingDirectReview
            )
        }
    }
    
    // MARK: - Top Header Bar (Native macOS Style)
    private var topHeaderBar: some View {
        HStack(alignment: .center, spacing: 14) {
            // Left: Brand Identity & APFS Tag
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.mcSurfaceHigh)
                        .frame(width: 28, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mcOutlineVariant.opacity(0.25), lineWidth: 1)
                        )
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.mcOnSurface)
                }
                
                Text("MacClean")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.mcOnSurface)
                
                Text("Storage Intelligence")
                    .font(.system(size: 12))
                    .foregroundColor(Color.mcOutline)
                
                Text("APFS Encrypted • Macintosh HD 1 TB")
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.mcSurfaceHigh.opacity(0.8))
                    .foregroundColor(Color.mcOnSurfaceVariant)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mcOutlineVariant.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }
            
            Spacer()
            
            // Right: Search Input, Drive Selector, Pindai Cepat, Settings
            HStack(spacing: 10) {
                // Search Input with ⌘F Badge
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(Color.mcOutline)
                    
                    TextField("Cari file atau bundle...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(Color.mcOnSurface)
                        .frame(width: 145)
                    
                    Text("⌘F")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.mcOutline)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.mcSurfaceHighest)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.mcOutlineVariant.opacity(0.4), lineWidth: 0.8)
                        )
                        .cornerRadius(4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.mcSurfaceHigh.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mcOutlineVariant.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(8)
                
                // Drive Selector
                HStack(spacing: 4) {
                    Image(systemName: "opticaldiscdrive")
                        .font(.system(size: 12))
                        .foregroundColor(Color.mcOutline)
                    Text("Macintosh HD (1 TB)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.mcOnSurface)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.mcSurfaceHigh.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mcOutlineVariant.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(8)
                
                // Pindai Cepat Action
                if viewModel.isScanning {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.65)
                        Text(viewModel.currentScanningStatus)
                            .font(.system(size: 12))
                            .foregroundColor(Color.mcOnSurface)
                            .frame(maxWidth: 120)
                            .lineLimit(1)
                        
                        Button("Batal") {
                            viewModel.cancelScan()
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.mcCoral)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.mcSurfaceHigh)
                    .cornerRadius(8)
                } else {
                    Button(action: {
                        viewModel.scan()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                            Text("Pindai Cepat")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color.mcOnSurface)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.mcSurfaceHigh)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mcOutlineVariant.opacity(0.4), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                // System Settings Icon
                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(Color.mcOutline)
                        .frame(width: 28, height: 28)
                        .background(Color.mcSurfaceHigh.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mcOutlineVariant.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.mcSurfaceLowest.opacity(0.85))
    }
    
    // MARK: - 4-Column Category Cards Grid
    private var categoryCardsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 160, maximum: .infinity), spacing: 14)],
            spacing: 14
        ) {
            ForEach(CleanupCategory.allCases) { cat in
                BentoCategoryCard(
                    category: cat,
                    items: viewModel.categoryItems[cat] ?? [],
                    selection: viewModel.selection,
                    onFilterSelected: {
                        if viewModel.selectedCategoryFilter == cat {
                            viewModel.selectedCategoryFilter = nil
                        } else {
                            viewModel.selectedCategoryFilter = cat
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Floating Bottom Action Dock
    private var floatingBottomActionDock: some View {
        let selectedCount = viewModel.selection.selectedItems.count
        let selectedBytes = viewModel.selection.selectedSize(from: viewModel.categoryItems)
        let totalEligible = viewModel.totalPotentialReclaimable
        let isAllSelected = viewModel.selection.isAllRecommendedSelected(from: viewModel.categoryItems)
        
        return HStack(alignment: .center, spacing: 16) {
            // Left: Shield Icon & Status Text
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.mcSurfaceHighest)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: "shield.fill")
                        .font(.system(size: 19))
                        .foregroundColor(Color.mcCyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(selectedCount == 0 ? "0 item dipilih" : "\(selectedCount) item dipilih")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.mcOnSurface)
                        
                        Text("•")
                            .foregroundColor(Color.mcOutline)
                        
                        Text(selectedCount == 0 ? "\(ByteFormatter.string(from: totalEligible)) siap dilepaskan" : "\(ByteFormatter.string(from: selectedBytes)) siap dilepaskan")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.mcPrimary)
                    }
                    
                    Text("Trash Safe: Dipindahkan ke Tempat Sampah, dapat dipulihkan kapan saja")
                        .font(.system(size: 11))
                        .foregroundColor(Color.mcOnSurfaceVariant)
                }
            }
            
            Spacer()
            
            // Right: CTA Action Buttons
            HStack(spacing: 10) {
                // Pilih Semua Rekomendasi / Batal Pilih
                Button(action: {
                    if isAllSelected {
                        viewModel.selection.clearSelection()
                    } else {
                        viewModel.selection.selectRecommended(in: viewModel.categoryItems)
                    }
                    viewModel.recalculateReclaimable()
                }) {
                    Text(isAllSelected ? "Batal Pilih Semua" : "Pilih Semua Rekomendasi")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.mcOnSurface)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.mcSurfaceHighest.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(totalEligible == 0)
                
                // Gradient Prominent Button: Bersihkan Sekarang
                Button(action: {
                    showingDirectReview = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.sparkles.fill")
                            .font(.system(size: 13))
                        Text(selectedCount > 0 ? "Bersihkan Sekarang (\(ByteFormatter.string(from: selectedBytes)))" : "Bersihkan Sekarang")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color.mcSurfaceLowest)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(LinearGradient.mcPrimaryCTA)
                    .cornerRadius(10)
                    .shadow(color: Color.mcCyanGlow.opacity(0.35), radius: 10, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(selectedCount == 0)
                .opacity(selectedCount == 0 ? 0.5 : 1.0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.mcSurfaceHigh.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mcOutlineVariant.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 10)
        .frame(maxWidth: 960)
    }
    
    // MARK: - Banners
    @ViewBuilder
    private var commonBanners: some View {
        if let result = viewModel.latestCleanupResult, viewModel.showCleanupSuccessBanner {
            cleanupSuccessBanner(result: result)
        }
        
        if !viewModel.scanWarnings.isEmpty {
            scanWarningBanner
        }
    }
    
    private func cleanupSuccessBanner(result: CleanupBeforeAfter) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 26))
                .foregroundColor(Color.mcEmerald)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Cleanup Successful • \(ByteFormatter.string(from: result.bytesMoved)) Moved to Trash")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.mcOnSurface)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.dismissCleanupBanner()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundColor(Color.mcOutline)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss notification")
                }
                
                HStack(spacing: 6) {
                    Text("Free space: \(ByteFormatter.string(from: result.beforeFreeBytes)) → \(ByteFormatter.string(from: result.effectiveAfterFreeBytes))")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurfaceVariant)
                    
                    Text("(+\(ByteFormatter.string(from: result.freeSpaceGain)) gained)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.mcEmerald)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(Color.mcOutline)
                    
                    Text("\(result.itemsMovedCount) items cleaned")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurfaceVariant)
                }
                
                HStack(spacing: 12) {
                    Text("Files are safe in macOS Trash. Empty Trash in Finder to permanently release physical space.")
                        .font(.caption2)
                        .foregroundColor(Color.mcOutline)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.openTrashInFinder()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.caption2)
                            Text("Open Trash")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.mcCyan)
                    }
                    .buttonStyle(.link)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mcEmerald.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.mcEmerald.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    private var scanWarningBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.mcCoral)
                Text("Beberapa folder dilewati saat pemindaian")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.mcOnSurface)
            }
            
            Text("macOS membatasi akses pada beberapa folder sistem. MacClean melewatinya dengan aman dan tetap menampilkan hasil dari area yang dapat diakses.")
                .font(.caption)
                .foregroundColor(Color.mcOnSurfaceVariant)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mcCoral.opacity(0.12))
        .cornerRadius(8)
    }
    
    private var loadingStoragePlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Membaca informasi penyimpanan macOS...")
                .font(.callout)
                .foregroundColor(Color.mcOutline)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }
}

// MARK: - Recommendation Modal
struct RecommendationExplanationView: View {
    let count: Int
    let bytes: Int64
    var onConfirm: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title)
                    .foregroundColor(Color.mcEmerald)
                Text("Rekomendasi Pembersihan")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.mcOnSurface)
            }
            .padding(.top, 8)
            
            Text("MacClean mengidentifikasi \(count) item dengan tingkat keamanan tinggi sebesar \(ByteFormatter.string(from: bytes)).")
                .font(.body)
                .foregroundColor(Color.mcOnSurfaceVariant)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.mcEmerald)
                        .font(.caption)
                    Text("Termasuk cache yang dibuat otomatis kembali dan sisa data aplikasi.")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurface)
                }
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.mcOutline)
                        .font(.caption)
                    Text("Mengecualikan runtime terlindungi, arsip penting, dan berkas pengguna.")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurface)
                }
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color.mcCoral)
                        .font(.caption)
                    Text("Berkas dipindahkan ke macOS Trash secara aman, dapat dipulihkan kapan saja.")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurface)
                }
            }
            .padding(12)
            .background(Color.mcSurfaceHigh)
            .cornerRadius(8)
            
            HStack(spacing: 16) {
                Button("Batal") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Terapkan Pilihan") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.mcCyan)
                .controlSize(.large)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 440)
        .background(Color.mcSurfaceContainer)
    }
}
