import Foundation

enum ItemStatus: String, Codable, Hashable, Sendable {
    case knownLeftover = "App Not Found (Leftover)"
    case possibleCandidate = "Possible Candidate"
    case unknown = "Unknown"
    case protected = "Protected"
    case knownCache = "Known Cache"
    case notJunk = "Not Junk"
    case safeToDelete = "Safe to Delete"
}

struct ScanResultItem: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    let path: URL
    let size: Int64
    let category: CleanupCategory
    let status: ItemStatus
    var ownerApplication: String?
    let explanation: String?
    var developerType: DeveloperDataType?
    var confidence: DetectionConfidence?
    var isRegenerable: Bool
    var structuredExplanation: CleanupExplanation?
    var filesystemIdentity: FilesystemIdentity?

    var identity: FilesystemIdentity {
        return filesystemIdentity ?? FilesystemIdentity(url: path)
    }

    var isEligibleForCleanup: Bool {
        guard status != .protected && status != .unknown && status != .notJunk && confidence != .low else {
            return false
        }
        return status == .knownCache || status == .knownLeftover || status == .safeToDelete
    }

    var confidenceTier: CleanupConfidenceTier {
        if developerType == .xcodeArchives || status == .protected || confidence == .low || status == .unknown || status == .notJunk {
            return .protected
        }
        if isEligibleForCleanup && confidence == .high {
            return .safeToClean
        }
        return .needsReview
    }

    var whyDialogTitle: String {
        switch confidenceTier {
        case .safeToClean:
            return "Why can MacClean clean this?"
        case .needsReview:
            return "Why does this require review?"
        case .protected:
            return "Why is this item protected?"
        }
    }

    var humanExplanationText: String {
        if let structured = structuredExplanation {
            return structured.whatIsIt
        }
        if category == .appLeftovers, let app = ownerApplication {
            return "This data belongs to '\(app)', which is no longer installed on your Mac."
        }
        if category == .caches {
            return "This is temporary application cache data that can normally be regenerated if needed."
        }
        if category == .developerData {
            if developerType == .xcodeArchives {
                return "Xcode Archives contain release builds, dSYM symbols, and distribution history."
            }
            return "This is developer cache or build artifact data."
        }
        if category == .largeFiles {
            return "This is a large file or folder discovered on your Mac. It requires personal review before taking action."
        }
        return explanation ?? "Discovered storage item."
    }

    var consequenceExplanationText: String {
        if let structured = structuredExplanation, let c = structured.consequence {
            return c
        }
        switch confidenceTier {
        case .safeToClean:
            return "Moving this item to Trash is safe. MacClean does not permanently delete files, and you can restore it from Trash if needed."
        case .needsReview:
            if category == .largeFiles {
                return "Deleting this item will remove your personal file or runtime data. Review carefully in Finder before moving to Trash."
            }
            return "Removing this cache may cause the application or tool to redownload dependencies the next time it runs."
        case .protected:
            return "MacClean keeps this data protected to avoid losing important archives, build outputs, or critical system state."
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        size: Int64,
        category: CleanupCategory,
        status: ItemStatus,
        ownerApplication: String? = nil,
        explanation: String? = nil,
        developerType: DeveloperDataType? = nil,
        confidence: DetectionConfidence? = nil,
        isRegenerable: Bool = true,
        structuredExplanation: CleanupExplanation? = nil,
        filesystemIdentity: FilesystemIdentity? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.category = category
        self.status = status
        self.ownerApplication = ownerApplication
        self.explanation = explanation
        self.developerType = developerType
        self.confidence = confidence
        self.isRegenerable = isRegenerable
        self.structuredExplanation = structuredExplanation
        self.filesystemIdentity = filesystemIdentity ?? FilesystemIdentity(url: path)
    }
}
