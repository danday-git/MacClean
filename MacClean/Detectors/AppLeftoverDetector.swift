import Foundation
#if canImport(AppKit)
import AppKit
#endif

protocol AppLeftoverDetecting: Sendable {
    func detectLeftovers(
        installedApplications: [InstalledApplication]
    ) async throws -> [ScanResultItem]
}

actor DefaultAppLeftoverDetector: AppLeftoverDetecting {
    
    private let registry: AppCleanupRegistering
    private let sizeCalculator: FileSizeCalculating
    
    init(registry: AppCleanupRegistering = AppCleanupRegistry(),
         sizeCalculator: FileSizeCalculating = DefaultFileSizeCalculator()) {
        self.registry = registry
        self.sizeCalculator = sizeCalculator
    }
    
    func detectLeftovers(installedApplications: [InstalledApplication]) async throws -> [ScanResultItem] {
        var leftoverItems: [ScanResultItem] = []
        var seenPaths = Set<String>()
        let fileManager = FileManager.default
        
        let installedBundleIDs = Set(installedApplications.compactMap { $0.bundleIdentifier?.lowercased() })
        let installedNames = Set(installedApplications.map { $0.name.lowercased() })
        let installedFileNames = Set(installedApplications.map { $0.bundleURL.lastPathComponent.lowercased() })
        
        for rule in registry.allRules() {
            try Task.checkCancellation()
            
            // Multi-layer safety verification: Is the application installed on the system?
            if isApplicationInstalled(
                rule: rule,
                installedBundleIDs: installedBundleIDs,
                installedNames: installedNames,
                installedFileNames: installedFileNames,
                fileManager: fileManager
            ) {
                continue
            }
            
            // App is NOT installed. Check its known paths.
            for location in rule.knownPaths {
                let url = location.resolvedURL()
                let normalizedPath = url.standardizedFileURL.path
                
                // Avoid checking duplicate paths across multiple rules or aliases
                if seenPaths.contains(normalizedPath) {
                    continue
                }
                
                // Safety check: ensure not protected
                if ProtectedPaths.isProtected(url: url) {
                    continue
                }
                
                // Ensure it is strictly contained within the home directory
                if !ProtectedPaths.isContained(child: url, parent: fileManager.homeDirectoryForCurrentUser) {
                    continue
                }
                
                // Check if the path exists
                if fileManager.fileExists(atPath: normalizedPath) {
                    seenPaths.insert(normalizedPath)
                    let size = await sizeCalculator.size(of: url)
                    
                    if size > 0 {
                        let item = ScanResultItem(
                            name: url.lastPathComponent,
                            path: url,
                            size: size,
                            category: .appLeftovers,
                            status: .knownLeftover,
                            ownerApplication: rule.applicationName,
                            explanation: "Aplikasi '\(rule.applicationName)' tidak ditemukan di Mac ini (sudah di-uninstall). File sisa (leftover) ini aman untuk dipindahkan ke Trash guna menghemat ruang penyimpanan."
                        )
                        leftoverItems.append(item)
                    }
                }
            }
        }
        
        return leftoverItems.sorted { $0.size > $1.size }
    }
    
    /// Multi-layer safety verification to guarantee that no installed application is ever misclassified as a leftover.
    private func isApplicationInstalled(
        rule: AppCleanupRule,
        installedBundleIDs: Set<String>,
        installedNames: Set<String>,
        installedFileNames: Set<String>,
        fileManager: FileManager
    ) -> Bool {
        // 1. Check all registered bundle identifiers (including alternatives)
        let ruleBundleIDs = Set(rule.allBundleIdentifiers.map { $0.lowercased() })
        if !installedBundleIDs.isDisjoint(with: ruleBundleIDs) {
            return true
        }
        
        // 2. Check application names (case-insensitive exact match against discovered apps)
        let ruleNames = Set(rule.allApplicationNames.map { $0.lowercased() })
        if !installedNames.isDisjoint(with: ruleNames) {
            return true
        }
        
        // 3. Check installed .app filenames (e.g. "discord.app", "code.app")
        for name in rule.allApplicationNames {
            let appFilename = "\(name.lowercased()).app"
            if installedFileNames.contains(appFilename) {
                return true
            }
        }
        
        // 4. Direct filesystem verification in common macOS application directories
        let appDirectories = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        
        for dir in appDirectories {
            for name in rule.allApplicationNames {
                let candidateURL = dir.appendingPathComponent("\(name).app")
                if fileManager.fileExists(atPath: candidateURL.path) {
                    return true
                }
            }
        }
        
        // 5. Native macOS LaunchServices check via NSWorkspace
        #if canImport(AppKit)
        for bundleID in rule.allBundleIdentifiers {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
               fileManager.fileExists(atPath: appURL.path) {
                return true
            }
        }
        
        // 6. Active running processes check (if app process is currently active)
        let runningBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier?.lowercased() })
        if !runningBundleIDs.isDisjoint(with: ruleBundleIDs) {
            return true
        }
        let runningNames = Set(NSWorkspace.shared.runningApplications.compactMap { $0.localizedName?.lowercased() })
        if !runningNames.isDisjoint(with: ruleNames) {
            return true
        }
        #endif
        
        return false
    }
}
