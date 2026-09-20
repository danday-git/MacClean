import Foundation

struct CleanupExplanation: Hashable, Codable, Sendable {
    let whatIsIt: String
    let whyDetected: String
    let canRegenerate: Bool?
    let consequence: String?
    let disabledReason: String?
    
    init(
        whatIsIt: String,
        whyDetected: String,
        canRegenerate: Bool? = nil,
        consequence: String? = nil,
        disabledReason: String? = nil
    ) {
        self.whatIsIt = whatIsIt
        self.whyDetected = whyDetected
        self.canRegenerate = canRegenerate
        self.consequence = consequence
        self.disabledReason = disabledReason
    }
}
