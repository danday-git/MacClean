import Foundation

enum AppDataLocation: Hashable, Sendable {
    case applicationSupport(relativePath: String)
    case caches(relativePath: String)
    case containers(relativePath: String)
    case groupContainers(relativePath: String)
    case preferences(relativePath: String)
    case logs(relativePath: String)
    
    func resolvedURL(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        let libraryDir = homeDirectory.appendingPathComponent("Library")
        switch self {
        case .applicationSupport(let path):
            return libraryDir.appendingPathComponent("Application Support").appendingPathComponent(sanitize(path: path)).standardizedFileURL
        case .caches(let path):
            return libraryDir.appendingPathComponent("Caches").appendingPathComponent(sanitize(path: path)).standardizedFileURL
        case .containers(let path):
            return libraryDir.appendingPathComponent("Containers").appendingPathComponent(sanitize(path: path)).standardizedFileURL
        case .groupContainers(let path):
            return libraryDir.appendingPathComponent("Group Containers").appendingPathComponent(sanitize(path: path)).standardizedFileURL
        case .preferences(let path):
            return libraryDir.appendingPathComponent("Preferences").appendingPathComponent(sanitize(path: path)).standardizedFileURL
        case .logs(let path):
            return libraryDir.appendingPathComponent("Logs").appendingPathComponent(sanitize(path: path)).standardizedFileURL
        }
    }
    
    private func sanitize(path: String) -> String {
        let cleanComponents = path.split(separator: "/").filter { $0 != ".." && $0 != "." && !$0.isEmpty }
        return cleanComponents.joined(separator: "/")
    }
}
