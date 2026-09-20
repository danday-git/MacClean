import Foundation

enum DeveloperDataType: String, Codable, Hashable, Sendable, CaseIterable {
    case npmCache = "npm Cache"
    case yarnCache = "Yarn Cache"
    case pnpmStore = "pnpm Store"
    case gradleCache = "Gradle Cache"
    case mavenRepository = "Maven Repository"
    case cocoapodsCache = "CocoaPods Cache"
    case xcodeDerivedData = "Xcode Derived Data"
    case xcodeArchives = "Xcode Archives"
    case androidBuildCache = "Android Studio Cache"
    case homebrewCache = "Homebrew Cache"
    case dockerCache = "Docker Data"
    case colimaData = "Colima Data"
    case unknown = "Developer Artifact"
}
