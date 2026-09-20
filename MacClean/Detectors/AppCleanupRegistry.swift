import Foundation

protocol AppCleanupRegistering: Sendable {
    func allRules() -> [AppCleanupRule]
}

struct AppCleanupRegistry: AppCleanupRegistering {
    
    func allRules() -> [AppCleanupRule] {
        return [
            AppCleanupRule(
                bundleIdentifier: "com.hnc.Discord",
                alternativeBundleIdentifiers: [
                    "com.discord.Discord",
                    "com.discord.canary",
                    "com.discord.ptb"
                ],
                applicationName: "Discord",
                alternativeAppNames: ["Discord Canary", "Discord PTB"],
                knownPaths: [
                    .applicationSupport(relativePath: "discord"),
                    .caches(relativePath: "com.hnc.Discord"),
                    .caches(relativePath: "com.hnc.Discord.ShipIt"),
                    .caches(relativePath: "com.discord.Discord"),
                    .caches(relativePath: "com.discord.Discord.ShipIt"),
                    .preferences(relativePath: "com.hnc.Discord.plist"),
                    .preferences(relativePath: "com.discord.Discord.plist"),
                    .logs(relativePath: "Discord")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.anthropic.claudefordesktop",
                alternativeBundleIdentifiers: ["com.anthropic.claude"],
                applicationName: "Claude",
                alternativeAppNames: ["Claude Desktop"],
                knownPaths: [
                    .applicationSupport(relativePath: "Claude"),
                    .caches(relativePath: "com.anthropic.claudefordesktop"),
                    .caches(relativePath: "com.anthropic.claudefordesktop.ShipIt"),
                    .caches(relativePath: "com.anthropic.claude"),
                    .caches(relativePath: "com.anthropic.claude.ShipIt"),
                    .preferences(relativePath: "com.anthropic.claudefordesktop.plist"),
                    .preferences(relativePath: "com.anthropic.claude.plist"),
                    .logs(relativePath: "Claude")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.tinyspeck.slackmacgap",
                alternativeBundleIdentifiers: ["com.slack.Slack"],
                applicationName: "Slack",
                alternativeAppNames: ["Slack"],
                knownPaths: [
                    .applicationSupport(relativePath: "Slack"),
                    .caches(relativePath: "com.tinyspeck.slackmacgap"),
                    .caches(relativePath: "com.tinyspeck.slackmacgap.ShipIt"),
                    .preferences(relativePath: "com.tinyspeck.slackmacgap.plist"),
                    .logs(relativePath: "Slack")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.roblox.RobloxPlayer",
                alternativeBundleIdentifiers: ["com.roblox.RobloxStudio"],
                applicationName: "Roblox",
                alternativeAppNames: ["RobloxPlayer", "RobloxStudio"],
                knownPaths: [
                    .applicationSupport(relativePath: "Roblox"),
                    .caches(relativePath: "com.roblox.RobloxPlayer"),
                    .preferences(relativePath: "com.roblox.RobloxPlayer.plist"),
                    .preferences(relativePath: "com.roblox.RobloxPlayerChannel.plist")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "notion.id",
                alternativeBundleIdentifiers: ["notion.id.desktop"],
                applicationName: "Notion",
                alternativeAppNames: ["Notion"],
                knownPaths: [
                    .applicationSupport(relativePath: "Notion"),
                    .caches(relativePath: "notion.id"),
                    .caches(relativePath: "notion.id.ShipIt"),
                    .preferences(relativePath: "notion.id.plist"),
                    .logs(relativePath: "Notion")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.netease.mumu.nemux-global",
                alternativeBundleIdentifiers: [
                    "com.netease.nemu",
                    "com.netease.mumu",
                    "com.netease.mumu.nemux-global.emulator",
                    "com.netease.mumu.nemux-global.launcher"
                ],
                applicationName: "MuMu Player",
                alternativeAppNames: ["Nemu", "MuMuPlayer", "MuMu Player Pro"],
                knownPaths: [
                    .applicationSupport(relativePath: "com.netease.mumu.nemux-global.pdata"),
                    .applicationSupport(relativePath: "Nemu"),
                    .caches(relativePath: "com.netease.mumu.nemux-global"),
                    .caches(relativePath: "com.netease.mumu.nemux-global.emulator"),
                    .caches(relativePath: "com.netease.mumu.nemux-global.launcher"),
                    .caches(relativePath: "com.netease.nemu"),
                    .preferences(relativePath: "com.netease.mumu.nemux-global.plist"),
                    .preferences(relativePath: "com.netease.mumu.nemux-global.emulator.plist"),
                    .preferences(relativePath: "com.netease.mumu.nemux-global.launcher.plist"),
                    .preferences(relativePath: "9699UND7H5.group.com.netease.mumu.nemux-global.default.plist"),
                    .preferences(relativePath: "com.netease.nemu.plist")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.nox.NoxAppPlayer",
                alternativeBundleIdentifiers: ["com.bignox.noxappplayer", "com.nox.Nox"],
                applicationName: "Nox App Player",
                alternativeAppNames: ["Nox", "NoxPlayer", "NoxAppPlayer"],
                knownPaths: [
                    .applicationSupport(relativePath: "NoxAppPlayer"),
                    .applicationSupport(relativePath: "NoxInstaller"),
                    .caches(relativePath: "NoxAppPlayer")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.google.android.studio",
                alternativeBundleIdentifiers: ["com.google.android.studio-preview"],
                applicationName: "Android Studio",
                alternativeAppNames: ["AndroidStudio"],
                knownPaths: [
                    .applicationSupport(relativePath: "Google/AndroidStudio"),
                    .caches(relativePath: "Google/AndroidStudio"),
                    .preferences(relativePath: "com.google.android.studio.plist"),
                    .logs(relativePath: "Google/AndroidStudio")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.microsoft.VSCode",
                alternativeBundleIdentifiers: ["com.microsoft.VSCodeInsiders"],
                applicationName: "Visual Studio Code",
                alternativeAppNames: ["Code", "Visual Studio Code - Insiders"],
                knownPaths: [
                    .applicationSupport(relativePath: "Code"),
                    .caches(relativePath: "com.microsoft.VSCode"),
                    .caches(relativePath: "com.microsoft.VSCode.ShipIt"),
                    .preferences(relativePath: "com.microsoft.VSCode.plist"),
                    .logs(relativePath: "Code")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.todesktop.230313mzl4w4u92",
                alternativeBundleIdentifiers: ["com.cursor.Cursor"],
                applicationName: "Cursor",
                alternativeAppNames: ["Cursor"],
                knownPaths: [
                    .applicationSupport(relativePath: "Cursor"),
                    .caches(relativePath: "com.todesktop.230313mzl4w4u92"),
                    .caches(relativePath: "com.todesktop.230313mzl4w4u92.ShipIt"),
                    .preferences(relativePath: "com.todesktop.230313mzl4w4u92.plist"),
                    .logs(relativePath: "Cursor")
                ]
            ),
            AppCleanupRule(
                bundleIdentifier: "com.postmanlabs.mac",
                alternativeBundleIdentifiers: ["com.postman.postman"],
                applicationName: "Postman",
                alternativeAppNames: ["Postman"],
                knownPaths: [
                    .applicationSupport(relativePath: "Postman"),
                    .caches(relativePath: "com.postmanlabs.mac"),
                    .caches(relativePath: "com.postmanlabs.mac.ShipIt"),
                    .preferences(relativePath: "com.postmanlabs.mac.plist"),
                    .logs(relativePath: "Postman")
                ]
            )
        ]
    }
}
