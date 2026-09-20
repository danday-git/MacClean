import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
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
                                selection: viewModel.selection,
                                onSelectionChanged: {
                                    viewModel.recalculateReclaimable()
                                }
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
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            NSApp.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
        }
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
                
                Text(languageManager.language == .indonesian ? "Kecerdasan Penyimpanan" : "Storage Intelligence")
                    .font(.system(size: 12))
                    .foregroundColor(Color.mcOutline)
                
                let totalSpaceStr = viewModel.summary?.totalSpace != nil ? " \(ByteFormatter.string(from: viewModel.summary!.totalSpace))" : ""
                Text("APFS • Macintosh HD\(totalSpaceStr)")
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
            
            // Right: Multi-Language Switcher, Light/Dark Mode Toggle
            HStack(spacing: 8) {
                // Multi-Language Switcher Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        languageManager.toggle()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundColor(Color.mcCyan)
                        Text(languageManager.language.shortLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.mcOnSurface)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5.5)
                    .background(Color.mcSurfaceHigh.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.mcOutlineVariant.opacity(0.25), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help(languageManager.language == .indonesian ? "Beralih ke English" : "Switch to Bahasa Indonesia")
                .contextMenu {
                    Button("Bahasa Indonesia (ID)") {
                        languageManager.language = .indonesian
                    }
                    Button("English (EN)") {
                        languageManager.language = .english
                    }
                }
                
                // Light / Dark Mode Toggle Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDarkMode.toggle()
                        NSApp.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isDarkMode ? Color.mcViolet : Color.mcCyan)
                        Text(isDarkMode ? (languageManager.language == .indonesian ? "Gelap" : "Dark") : (languageManager.language == .indonesian ? "Terang" : "Light"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.mcOnSurface)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5.5)
                    .background(Color.mcSurfaceHigh.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.mcOutlineVariant.opacity(0.25), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help(isDarkMode ? (languageManager.language == .indonesian ? "Beralih ke Mode Terang" : "Switch to Light Mode") : (languageManager.language == .indonesian ? "Beralih ke Mode Gelap" : "Switch to Dark Mode"))
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
                    isFilterActive: viewModel.selectedCategoryFilter == cat,
                    onFilterSelected: {
                        if viewModel.selectedCategoryFilter == cat {
                            viewModel.selectedCategoryFilter = nil
                        } else {
                            viewModel.selectedCategoryFilter = cat
                        }
                    },
                    onSelectionChanged: {
                        viewModel.recalculateReclaimable()
                    }
                )
            }
        }
    }
    
    // MARK: - Floating Bottom Action Dock (Unified Primary Action)
    private var floatingBottomActionDock: some View {
        let isID = languageManager.language == .indonesian
        let selectedCount = viewModel.selection.selectedItems.count
        let selectedBytes = viewModel.selection.selectedSize(from: viewModel.categoryItems)
        let totalEligible = viewModel.totalPotentialReclaimable
        let hasScanned = viewModel.scanSummary != nil
        
        return HStack(alignment: .center, spacing: 16) {
            // Left: Shield/Sparkle Icon & Dynamic Status Description
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.mcSurfaceHighest)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: hasScanned ? "shield.fill" : "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(Color.mcCyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.isScanning {
                        HStack(spacing: 6) {
                            Text(isID ? "Memindai Penyimpanan..." : "Scanning Storage...")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.mcOnSurface)
                            
                            Text("•")
                                .foregroundColor(Color.mcOutline)
                            
                            Text(viewModel.localizedScanningStatus(for: languageManager.language))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.mcCyan)
                                .lineLimit(1)
                        }
                        
                        Text(isID ? "Memeriksa cache sistem, sisa aplikasi, dan file besar" : "Inspecting system caches, app leftovers, and large files")
                            .font(.system(size: 11))
                            .foregroundColor(Color.mcOnSurfaceVariant)
                    } else if !hasScanned {
                        HStack(spacing: 6) {
                            Text(isID ? "Pindai Sistem Siap Dilakukan" : "System Scan Ready")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.mcOnSurface)
                        }
                        
                        Text(isID ? "Analisis cepat & aman tanpa mengubah atau menghapus file Anda" : "Fast & safe analysis without modifying or deleting your files")
                            .font(.system(size: 11))
                            .foregroundColor(Color.mcOnSurfaceVariant)
                    } else {
                        HStack(spacing: 6) {
                            Text(selectedCount == 0 ? (isID ? "0 item dipilih" : "0 items selected") : (isID ? "\(selectedCount) item dipilih" : "\(selectedCount) items selected"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.mcOnSurface)
                            
                            Text("•")
                                .foregroundColor(Color.mcOutline)
                            
                            Text(selectedCount == 0 ? (isID ? "\(ByteFormatter.string(from: totalEligible)) potensi dilepaskan" : "\(ByteFormatter.string(from: totalEligible)) potential to reclaim") : (isID ? "\(ByteFormatter.string(from: selectedBytes)) siap dilepaskan" : "\(ByteFormatter.string(from: selectedBytes)) ready to reclaim"))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.mcPrimary)
                        }
                        
                        Text(isID ? "Trash Safe: Dipindahkan ke Tempat Sampah, dapat dipulihkan kapan saja" : "Trash Safe: Moved to macOS Trash, can be restored at any time")
                            .font(.system(size: 11))
                            .foregroundColor(Color.mcOnSurfaceVariant)
                    }
                }
            }
            
            Spacer()
            
            // Right: Unified CTA Action Controls
            HStack(spacing: 10) {
                if viewModel.isScanning {
                    // Scanning State Controls
                    HStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(0.7)
                        
                        Button(action: {
                            viewModel.cancelScan()
                        }) {
                            Text(isID ? "Batal" : "Cancel")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.mcCoral)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.mcSurfaceHighest)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.mcCoral.opacity(0.4), lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                } else if !hasScanned {
                    // Pre-Scan State: Pindai Cepat is the Primary CTA!
                    Button(action: {
                        viewModel.scan()
                    }) {
                        HStack(spacing: 7) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .bold))
                            Text(isID ? "Mulai Pindai Cepat" : "Start Quick Scan")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color.mcOnPrimaryCTA)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(LinearGradient.mcPrimaryCTA)
                        .cornerRadius(10)
                        .shadow(color: Color.mcCyanGlow.opacity(0.4), radius: 10, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Post-Scan State: Pindai Ulang + Bersihkan Sekarang
                    Button(action: {
                        viewModel.scan()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                            Text(isID ? "Pindai Ulang" : "Rescan")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color.mcOnSurface)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.mcSurfaceHigh)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mcOutlineVariant.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help(isID ? "Pindai ulang sistem penyimpanan" : "Rescan storage system")
                    
                    // Gradient Prominent Button: Bersihkan Sekarang
                    Button(action: {
                        showingDirectReview = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.sparkles.fill")
                                .font(.system(size: 13))
                            let cleanTitle = isID ? "Bersihkan Sekarang" : "Clean Now"
                            Text(selectedCount > 0 ? "\(cleanTitle) (\(ByteFormatter.string(from: selectedBytes)))" : cleanTitle)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selectedCount > 0 ? Color.mcOnPrimaryCTA : Color.mcOutline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCount > 0 ? AnyView(LinearGradient.mcPrimaryCTA) : AnyView(Color.mcSurfaceHigh))
                        .cornerRadius(10)
                        .shadow(color: selectedCount > 0 ? Color.mcCyanGlow.opacity(0.35) : Color.clear, radius: 10, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedCount == 0)
                }
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
        let isID = languageManager.language == .indonesian
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 26))
                .foregroundColor(Color.mcEmerald)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    let title = isID ? "Pembersihan Berhasil • \(ByteFormatter.string(from: result.bytesMoved)) Dipindahkan ke Tempat Sampah" : "Cleanup Successful • \(ByteFormatter.string(from: result.bytesMoved)) Moved to Trash"
                    Text(title)
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
                    .help(isID ? "Tutup notifikasi" : "Dismiss notification")
                }
                
                HStack(spacing: 6) {
                    let freeText = isID ? "Ruang bebas: \(ByteFormatter.string(from: result.beforeFreeBytes)) → \(ByteFormatter.string(from: result.effectiveAfterFreeBytes))" : "Free space: \(ByteFormatter.string(from: result.beforeFreeBytes)) → \(ByteFormatter.string(from: result.effectiveAfterFreeBytes))"
                    Text(freeText)
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurfaceVariant)
                    
                    let gainText = isID ? "(+\(ByteFormatter.string(from: result.freeSpaceGain)) bertambah)" : "(+\(ByteFormatter.string(from: result.freeSpaceGain)) gained)"
                    Text(gainText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.mcEmerald)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(Color.mcOutline)
                    
                    let countText = isID ? "\(result.itemsMovedCount) item dibersihkan" : "\(result.itemsMovedCount) items cleaned"
                    Text(countText)
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurfaceVariant)
                }
                
                HStack(spacing: 12) {
                    let noteText = isID ? "Berkas aman di Tempat Sampah. Kosongkan Tempat Sampah di Finder untuk melepaskan ruang fisik secara permanen." : "Files are safe in macOS Trash. Empty Trash in Finder to permanently release physical space."
                    Text(noteText)
                        .font(.caption2)
                        .foregroundColor(Color.mcOutline)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.openTrashInFinder()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.caption2)
                            Text(isID ? "Buka Tempat Sampah" : "Open Trash")
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
        let isID = languageManager.language == .indonesian
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.mcCoral)
                Text(isID ? "Beberapa folder dilewati saat pemindaian" : "Some folders were skipped during scanning")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.mcOnSurface)
            }
            
            Text(isID ? "macOS membatasi akses pada beberapa folder sistem. MacClean melewatinya dengan aman dan tetap menampilkan hasil dari area yang dapat diakses." : "macOS restricts access to certain system folders. MacClean safely skips them and shows results from accessible areas.")
                .font(.caption)
                .foregroundColor(Color.mcOnSurfaceVariant)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mcCoral.opacity(0.12))
        .cornerRadius(8)
    }
    
    private var loadingStoragePlaceholder: some View {
        let isID = languageManager.language == .indonesian
        return VStack(spacing: 12) {
            ProgressView()
            Text(isID ? "Membaca informasi penyimpanan macOS..." : "Reading macOS storage telemetry...")
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
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        let isID = languageManager.language == .indonesian
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title)
                    .foregroundColor(Color.mcEmerald)
                Text(isID ? "Rekomendasi Pembersihan" : "Recommended Cleanup")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.mcOnSurface)
            }
            .padding(.top, 8)
            
            let introText = isID ? "MacClean mengidentifikasi \(count) item dengan tingkat keamanan tinggi sebesar \(ByteFormatter.string(from: bytes))." : "MacClean identified \(count) high-safety items totaling \(ByteFormatter.string(from: bytes))."
            Text(introText)
                .font(.body)
                .foregroundColor(Color.mcOnSurfaceVariant)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.mcEmerald)
                        .font(.caption)
                    Text(isID ? "Termasuk cache yang dibuat otomatis kembali dan sisa data aplikasi." : "Includes auto-regenerated caches and residual app data.")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurface)
                }
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.mcOutline)
                        .font(.caption)
                    Text(isID ? "Mengecualikan runtime terlindungi, arsip penting, dan berkas pengguna." : "Excludes protected runtimes, critical archives, and user documents.")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurface)
                }
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color.mcCoral)
                        .font(.caption)
                    Text(isID ? "Berkas dipindahkan ke macOS Trash secara aman, dapat dipulihkan kapan saja." : "Files are safely moved to macOS Trash and can be restored at any time.")
                        .font(.caption)
                        .foregroundColor(Color.mcOnSurface)
                }
            }
            .padding(12)
            .background(Color.mcSurfaceHigh)
            .cornerRadius(8)
            
            HStack(spacing: 16) {
                Button(isID ? "Batal" : "Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(isID ? "Terapkan Pilihan" : "Apply Selection") {
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
