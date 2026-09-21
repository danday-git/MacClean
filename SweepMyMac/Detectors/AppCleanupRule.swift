import Foundation

struct AppCleanupRule: Hashable, Sendable {
    let bundleIdentifier: String
    var alternativeBundleIdentifiers: [String] = []
    let applicationName: String
    var alternativeAppNames: [String] = []
    let knownPaths: [AppDataLocation]
    
    init(
        bundleIdentifier: String,
        alternativeBundleIdentifiers: [String] = [],
        applicationName: String,
        alternativeAppNames: [String] = [],
        knownPaths: [AppDataLocation]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.alternativeBundleIdentifiers = alternativeBundleIdentifiers
        self.applicationName = applicationName
        self.alternativeAppNames = alternativeAppNames
        self.knownPaths = knownPaths
    }
    
    var allBundleIdentifiers: [String] {
        return [bundleIdentifier] + alternativeBundleIdentifiers
    }
    
    var allApplicationNames: [String] {
        return [applicationName] + alternativeAppNames
    }
}
