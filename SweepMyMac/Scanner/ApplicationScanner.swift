import Foundation

protocol ApplicationScanner: Sendable {
    func scanInstalledApplications() async throws -> [InstalledApplication]
}

actor DefaultApplicationScanner: ApplicationScanner {
    
    func scanInstalledApplications() async throws -> [InstalledApplication] {
        let fileManager = FileManager.default
        var installedApps: [InstalledApplication] = []
        
        let searchDirectories = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        
        for dir in searchDirectories {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for appURL in contents where appURL.pathExtension == "app" {
                if let bundle = Bundle(url: appURL) {
                    let bundleID = bundle.bundleIdentifier
                    // Fallback to filename if CFBundleDisplayName or CFBundleName is missing
                    let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String 
                                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                                ?? appURL.deletingPathExtension().lastPathComponent
                    
                    let id = bundleID ?? appURL.path
                    
                    installedApps.append(
                        InstalledApplication(
                            id: id,
                            name: name,
                            bundleIdentifier: bundleID,
                            bundleURL: appURL
                        )
                    )
                }
            }
        }
        
        return installedApps
    }
}
