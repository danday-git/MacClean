import Foundation

struct DeveloperDataRule: Identifiable, Sendable {
    let id: String
    let name: String
    let type: DeveloperDataType
    let relativePaths: [String] // Relative to user home directory
    let confidence: DetectionConfidence
    let isRegenerable: Bool
    let isSelectableByDefault: Bool
    let isProtected: Bool // If true, marked as protected / informational only
    let description: String
    let consequence: String
    let verificationCheck: (@Sendable (URL) -> Bool)?
    
    init(
        id: String,
        name: String,
        type: DeveloperDataType,
        relativePaths: [String],
        confidence: DetectionConfidence,
        isRegenerable: Bool = true,
        isSelectableByDefault: Bool = false,
        isProtected: Bool = false,
        description: String,
        consequence: String,
        verificationCheck: (@Sendable (URL) -> Bool)? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.relativePaths = relativePaths
        self.confidence = confidence
        self.isRegenerable = isRegenerable
        self.isSelectableByDefault = isSelectableByDefault
        self.isProtected = isProtected
        self.description = description
        self.consequence = consequence
        self.verificationCheck = verificationCheck
    }
}
