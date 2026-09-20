import Foundation

struct CacheRule: Hashable, Sendable {
    let bundleIdentifier: String
    let applicationName: String
    let relativePaths: [String]
}

protocol CacheRuleRegistering: Sendable {
    func allRules() -> [CacheRule]
}

struct DefaultCacheRuleRegistry: CacheRuleRegistering {
    func allRules() -> [CacheRule] {
        return [
            CacheRule(
                bundleIdentifier: "com.anthropic.claude",
                applicationName: "Claude",
                relativePaths: [
                    "com.anthropic.claude",
                    "com.anthropic.claude.ShipIt"
                ]
            ),
            CacheRule(
                bundleIdentifier: "com.tinyspeck.slackmacgap",
                applicationName: "Slack",
                relativePaths: [
                    "com.tinyspeck.slackmacgap",
                    "com.tinyspeck.slackmacgap.ShipIt"
                ]
            ),
            CacheRule(
                bundleIdentifier: "com.hnc.Discord",
                applicationName: "Discord",
                relativePaths: [
                    "com.hnc.Discord",
                    "com.hnc.Discord.ShipIt",
                    "com.discord.Discord",
                    "com.discord.Discord.ShipIt"
                ]
            ),
            CacheRule(
                bundleIdentifier: "com.microsoft.VSCode",
                applicationName: "Visual Studio Code",
                relativePaths: [
                    "com.microsoft.VSCode",
                    "com.microsoft.VSCode.ShipIt"
                ]
            ),
            CacheRule(
                bundleIdentifier: "com.todesktop.230313mzl4w4u92",
                applicationName: "Cursor",
                relativePaths: [
                    "com.todesktop.230313mzl4w4u92",
                    "com.todesktop.230313mzl4w4u92.ShipIt"
                ]
            ),
            CacheRule(
                bundleIdentifier: "com.postmanlabs.mac",
                applicationName: "Postman",
                relativePaths: [
                    "com.postmanlabs.mac",
                    "com.postmanlabs.mac.ShipIt"
                ]
            )
        ]
    }
}
