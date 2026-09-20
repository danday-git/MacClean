import SwiftUI

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
    
    // Core Obsidian Dark Surfaces
    static let mcBackground = Color(hex: 0x0C1322)
    static let mcSurfaceLowest = Color(hex: 0x070E1D)
    static let mcSurfaceContainer = Color(hex: 0x191F2F)
    static let mcSurfaceHigh = Color(hex: 0x232A3A)
    static let mcSurfaceHighest = Color(hex: 0x2E3545)
    static let mcSurfaceVariant = Color(hex: 0x2E3545)
    
    // Text & Foreground
    static let mcOnSurface = Color(hex: 0xDCE2F7)
    static let mcOnSurfaceVariant = Color(hex: 0xBBC9CF)
    static let mcOutline = Color(hex: 0x859399)
    static let mcOutlineVariant = Color(hex: 0x3C494E)
    
    // Vibrant Brand Accents
    static let mcCyan = Color(hex: 0x47D6FF)
    static let mcCyanGlow = Color(hex: 0x00D2FF)
    static let mcPrimary = Color(hex: 0xA5E7FF)
    static let mcEmerald = Color(hex: 0x69F6B9)
    static let mcEmeraldDim = Color(hex: 0x48D99E)
    static let mcViolet = Color(hex: 0xE0B6FF)
    static let mcVioletContainer = Color(hex: 0x6D11AD)
    static let mcCoral = Color(hex: 0xFF5F56)
    static let mcCoralText = Color(hex: 0xFFB4AB)
}

// MARK: - Linear Gradients
extension LinearGradient {
    static let mcPrimaryCTA = LinearGradient(
        colors: [
            Color(hex: 0x00D2FF),
            Color(hex: 0x47D6FF),
            Color(hex: 0xE0B6FF)
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
