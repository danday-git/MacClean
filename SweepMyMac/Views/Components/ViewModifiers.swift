import SwiftUI
import AppKit

// MARK: - Interactive Hover Effect Modifier
struct InteractiveHoverModifier: ViewModifier {
    @State private var isHovered = false
    var scale: CGFloat = 1.012
    var hoverBackground: Color? = nil
    var hoverBorder: Color? = nil
    var cornerRadius: CGFloat = 8
    var changeCursorToPointer: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered && hoverBackground != nil ? hoverBackground! : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHovered && hoverBorder != nil ? hoverBorder! : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
                if changeCursorToPointer {
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            }
    }
}

// MARK: - Row Hover Highlight Modifier (No Scale, Just Subtle Tint)
struct RowHoverModifier: ViewModifier {
    @State private var isHovered = false
    var cornerRadius: CGFloat = 6
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHovered ? Color.secondary.opacity(0.2) : Color.clear, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Pointer Cursor Modifier
struct PointerCursorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Adds an interactive hover effect with slight scaling, background tint, and pointer cursor
    func interactiveCard(
        scale: CGFloat = 1.015,
        hoverBackground: Color = Color.accentColor.opacity(0.06),
        hoverBorder: Color = Color.accentColor.opacity(0.35),
        cornerRadius: CGFloat = 8,
        pointer: Bool = true
    ) -> some View {
        self.modifier(
            InteractiveHoverModifier(
                scale: scale,
                hoverBackground: hoverBackground,
                hoverBorder: hoverBorder,
                cornerRadius: cornerRadius,
                changeCursorToPointer: pointer
            )
        )
    }
    
    /// Adds subtle background highlight on hover for list/table rows
    func interactiveRow(cornerRadius: CGFloat = 6) -> some View {
        self.modifier(RowHoverModifier(cornerRadius: cornerRadius))
    }
    
    /// Changes macOS cursor to pointing hand on hover
    func pointerCursor() -> some View {
        self.modifier(PointerCursorModifier())
    }
}
