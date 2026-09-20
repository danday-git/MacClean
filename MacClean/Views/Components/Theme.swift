import SwiftUI

import AppKit

// MARK: - Color Palette Matching Reference
extension Color {
    // Hex helper
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
    
    // Dynamic Color Provider supporting Light and Dark Appearances
    static func dynamic(light: UInt, dark: UInt, alpha: Double = 1.0) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua])
            let hex = (match == .aqua) ? light : dark
            return NSColor(
                srgbRed: CGFloat((hex >> 16) & 0xff) / 255.0,
                green: CGFloat((hex >> 8) & 0xff) / 255.0,
                blue: CGFloat(hex & 0xff) / 255.0,
                alpha: CGFloat(alpha)
            )
        }))
    }
    
    // Core Dynamic Surfaces (Obsidian Dark vs Clean Slate Light)
    static let mcBackground = dynamic(light: 0xF4F6F9, dark: 0x0C1322)
    static let mcSurfaceLowest = dynamic(light: 0xFFFFFF, dark: 0x070E1D)
    static let mcSurfaceContainer = dynamic(light: 0xEDF2F7, dark: 0x191F2F)
    static let mcSurfaceHigh = dynamic(light: 0xE2E8F0, dark: 0x232A3A)
    static let mcSurfaceHighest = dynamic(light: 0xCBD5E1, dark: 0x2E3545)
    static let mcSurfaceVariant = dynamic(light: 0xD8E1EA, dark: 0x2E3545)
    
    // Text & Foreground
    static let mcOnSurface = dynamic(light: 0x0F172A, dark: 0xDCE2F7)
    static let mcOnSurfaceVariant = dynamic(light: 0x475569, dark: 0xBBC9CF)
    static let mcOutline = dynamic(light: 0x94A3B8, dark: 0x859399)
    static let mcOutlineVariant = dynamic(light: 0xE2E8F0, dark: 0x3C494E)
    static let mcOnPrimaryCTA = dynamic(light: 0xFFFFFF, dark: 0x070E1D)
    
    // Vibrant Brand Accents
    static let mcCyan = dynamic(light: 0x0284C7, dark: 0x47D6FF)
    static let mcCyanGlow = dynamic(light: 0x0EA5E9, dark: 0x00D2FF)
    static let mcPrimary = dynamic(light: 0x0369A1, dark: 0xA5E7FF)
    static let mcEmerald = dynamic(light: 0x059669, dark: 0x69F6B9)
    static let mcEmeraldDim = dynamic(light: 0x047857, dark: 0x48D99E)
    static let mcViolet = dynamic(light: 0x7C3AED, dark: 0xE0B6FF)
    static let mcVioletContainer = dynamic(light: 0xDDD6FE, dark: 0x6D11AD)
    static let mcCoral = dynamic(light: 0xDC2626, dark: 0xFF5F56)
    static let mcCoralText = dynamic(light: 0xB91C1C, dark: 0xFFB4AB)
}

// MARK: - Linear Gradients
extension LinearGradient {
    static let mcPrimaryCTA = LinearGradient(
        colors: [
            Color.mcCyanGlow,
            Color.mcCyan,
            Color.mcViolet
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let mcCardGlow = LinearGradient(
        colors: [
            Color.mcCyan.opacity(0.15),
            Color.mcViolet.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers
struct MCCardModifier: ViewModifier {
    var isSelected: Bool = false
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(Color.mcSurfaceContainer.opacity(0.75))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected ? Color.mcCyan.opacity(0.4) : Color.mcOutlineVariant.opacity(0.25),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .cornerRadius(cornerRadius)
            .shadow(color: isSelected ? Color.mcCyan.opacity(0.08) : Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func mcCard(isSelected: Bool = false, cornerRadius: CGFloat = 16) -> some View {
        self.modifier(MCCardModifier(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}

// MARK: - Multi-Language Localization
enum AppLanguage: String, CaseIterable, Identifiable {
    case indonesian = "id"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .indonesian: return "Bahasa Indonesia"
        case .english: return "English"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .indonesian: return "Bahasa (ID)"
        case .english: return "English (EN)"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.indonesian.rawValue
        self.language = AppLanguage(rawValue: saved) ?? .indonesian
    }
    
    func toggle() {
        language = (language == .indonesian) ? .english : .indonesian
    }
}

