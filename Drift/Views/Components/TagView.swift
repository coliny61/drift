import SwiftUI

struct TagView: View {
    let text: String
    var color: Color = Color(hex: "FF6B35")
    var style: TagStyle = .filled

    enum TagStyle {
        case filled, outlined, subtle
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: style == .outlined ? 1 : 0)
            )
    }

    private var backgroundColor: Color {
        switch style {
        case .filled: return color
        case .outlined: return .clear
        case .subtle: return color.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled: return .white
        case .outlined: return color
        case .subtle: return color
        }
    }

    private var borderColor: Color {
        style == .outlined ? color.opacity(0.5) : .clear
    }
}
