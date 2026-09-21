import Foundation

struct ProtectedPaths: Sendable {
    
    // Explicit System Protected Prefixes
    static let systemProtectedPrefixes: [String] = [
        "/System",
        "/System/Applications",
        "/Library",
        "/Applications",
        "/usr",
        "/bin",
        "/sbin",
        "/private",
        "/var",
        "/etc",
        "/tmp",
        "/opt",
        "/Volumes",
        "/dev"
    ]
    
    // User-Protected Folders and Files inside user home directory
    static let userProtectedRelativePaths: [String] = [
        "Desktop",
        "Documents",
        "Downloads",
        "Movies",
        "Music",
        "Pictures",
        ".ssh",
        ".gnupg",
        ".aws",
        "Library/Keychains",
        "Library/Mobile Documents",
        "Library/Mail",
        "Library/Messages",
        "Library/Safari",
        "Library/Cookies",
        "Library/Photos",
        "Library/Accounts",
        "Library/IdentityServices"
    ]
    
    static let userProtectedFolders: Set<String> = [
        "AddressBook",
        "CallHistoryDB",
        "CallHistoryTransactions",
        "CloudDocs",
        "CrashReporter",
        "Dock",
        "FaceTime",
        "Knowledge",
        "Quick Look",
        "iCloud",
        "SyncServices",
        "Keychains",
        "Safari"
    ]
    
    /// Checks if a given path string is protected (for backward compatibility).
    static func isProtected(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        return isProtected(url: url)
    }
    
    /// Checks if a given URL is protected against deletion, checking both canonical and raw standardized URLs.
    static func isProtected(url: URL, homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> Bool {
        let standardizedURL = url.standardizedFileURL
        let resolvedURL = url.standardizedFileURL.resolvingSymlinksInPath()
        
        return isProtectedPathString(standardizedURL.path, homeDirectory: homeDirectory) ||
               isProtectedPathString(resolvedURL.path, homeDirectory: homeDirectory)
    }
    
    private static func isProtectedPathString(_ path: String, homeDirectory: URL) -> Bool {
        let homeResolved = homeDirectory.standardizedFileURL.resolvingSymlinksInPath()
        let homePath = homeResolved.path
        
        // 1. Check root home directory itself (cannot trash home directory)
        if path == homePath {
            return true
        }
        
        // 2. Determine if the path is contained inside homeDirectory
        let pathURL = URL(fileURLWithPath: path)
        let isInsideHome = isContained(child: pathURL, parent: homeDirectory)
        
        if isInsideHome {
            // Check user-protected relative paths inside home
            for relPath in userProtectedRelativePaths {
                let protectedURL = homeDirectory.appendingPathComponent(relPath).standardizedFileURL.resolvingSymlinksInPath()
                let protectedPath = protectedURL.path
                if path == protectedPath || path.hasPrefix(protectedPath + "/") {
                    return true
                }
            }
            
            // Check user-protected application support folders
            for folder in userProtectedFolders {
                let appSupportProtected = homeDirectory.appendingPathComponent("Library/Application Support/\(folder)").standardizedFileURL.resolvingSymlinksInPath().path
                if path == appSupportProtected || path.hasPrefix(appSupportProtected + "/") {
                    return true
                }
            }
            return false
        } else {
            // Path is outside homeDirectory. Check system protected prefixes.
            for prefix in systemProtectedPrefixes {
                if path == prefix || path.hasPrefix(prefix + "/") {
                    return true
                }
            }
            return false
        }
    }
    
    /// Verifies that `child` is strictly a descendant of `parent` using standardized path components.
    /// Rejects sibling paths (e.g. /Users/test2 when parent is /Users/test) and rejects the parent itself.
    static func isContained(child: URL, parent: URL) -> Bool {
        let cleanChild = child.standardizedFileURL.resolvingSymlinksInPath()
        let cleanParent = parent.standardizedFileURL.resolvingSymlinksInPath()
        
        let childComponents = cleanChild.pathComponents
        let parentComponents = cleanParent.pathComponents
        
        // Child must be strictly deeper than parent
        guard childComponents.count > parentComponents.count else {
            return false
        }
        
        for (index, component) in parentComponents.enumerated() {
            if childComponents[index] != component {
                return false
            }
        }
        return true
    }
    
    static func isUserProtectedAppSupport(folderName: String) -> Bool {
        if folderName.lowercased().hasPrefix("com.apple.") {
            return true
        }
        return userProtectedFolders.contains(folderName)
    }
}
