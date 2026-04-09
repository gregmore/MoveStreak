import SwiftUI
import Foundation

enum AppTheme {
    static let cardCornerRadius: CGFloat = 18
    static let sectionCornerRadius: CGFloat = 22
    
    static var background: Color { Color(uiColor: .systemBackground) }
    static var cardBackground: Color { Color(uiColor: .systemBackground) }
    static var elevatedBackground: Color { Color(uiColor: .secondarySystemBackground) }
    
    static func gradient(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.18), color.opacity(0.07), AppTheme.background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func shadow(_ color: Color = .black, intensity: Double = 0.06) -> Color {
        color.opacity(intensity)
    }
    
    static var cardStroke: Color { Color.primary.opacity(0.08) }
    static var accentStroke: Color { Color.primary.opacity(0.10) }
    
    // Typography
    static func titleFont(size: CGFloat = 28, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    
    static func bodyFont(size: CGFloat = 17, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct AppTitle: ViewModifier {
    var size: CGFloat = 34
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .black, design: .rounded))
            .kerning(-0.5)
            .lineSpacing(2)
    }
}

struct AppHeadline: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, design: .rounded))
            .fontWeight(.bold)
            .lineSpacing(2)
    }
}

struct AppBody: ViewModifier {
    var color: Color = .secondary
    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.medium)
            .foregroundStyle(color)
            .lineSpacing(4)
    }
}

struct AppCard: ViewModifier {
    var accent: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous)
                    .stroke(accent == nil ? AppTheme.cardStroke : (accent ?? .blue).opacity(0.28), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow(intensity: 0.10), radius: 18, x: 0, y: 10)
    }
}

struct AppMeshCard: ViewModifier {
    var accent: Color? = nil
    var colors: [Color]
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background {
                AnimatedMeshBackground(colors: colors)
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.75))
                            .allowsHitTesting(false)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous)
                    .stroke(accent == nil ? AppTheme.cardStroke : (accent ?? .blue).opacity(0.28), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow(intensity: 0.12), radius: 22, x: 0, y: 12)
    }
}

struct AnimatedMeshBackground: View {
    var colors: [Color]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let base = min(w, h)
                
                context.blendMode = .plusLighter
                
                for i in 0..<max(3, colors.count) {
                    let c = colors[i % colors.count]
                    let phase = Double(i) * 0.9
                    let x = (w * 0.5) + CGFloat(sin(t * 0.35 + phase) * 0.35) * w
                    let y = (h * 0.5) + CGFloat(cos(t * 0.28 + phase) * 0.35) * h
                    let r = base * (0.55 + CGFloat(sin(t * 0.22 + phase)) * 0.12)
                    
                    var blob = context
                    blob.addFilter(.blur(radius: base * 0.22))
                    blob.opacity = 0.75
                    blob.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(c)
                    )
                }
            }
        }
    }
}

struct AppPill: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    var color: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(configuration.isPressed ? 0.80 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.accentStroke.opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: AppTheme.shadow(intensity: 0.12), radius: 16, x: 0, y: 10)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    var color: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(configuration.isPressed ? 0.14 : 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct CopyButton: View {
    let text: String
    var color: Color = .blue
    var size: CGFloat = 44
    var useText: Bool = false
    
    @State private var isCopied = false
    
    private var iconSize: CGFloat {
        size * 0.4
    }
    
    var body: some View {
        Button {
            UIPasteboard.general.string = text
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isCopied = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut) {
                    isCopied = false
                }
            }
        } label: {
            ZStack {
                if isCopied {
                    Image(systemName: "checkmark")
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    if useText {
                        Text("COPY")
                            .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                            .foregroundColor(color)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: iconSize + 2, weight: .medium))
                            .foregroundColor(color)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isCopied ? Color.green.opacity(0.12) : color.opacity(0.12))
            )
            .overlay(
                Circle()
                    .stroke(isCopied ? Color.green.opacity(0.2) : color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

extension View {
    func appCard(accent: Color? = nil) -> some View { modifier(AppCard(accent: accent)) }
    func appMeshCard(accent: Color? = nil, colors: [Color]) -> some View { modifier(AppMeshCard(accent: accent, colors: colors)) }
    func appPill(color: Color) -> some View { modifier(AppPill(color: color)) }
    
    func appTitle(size: CGFloat = 34) -> some View { modifier(AppTitle(size: size)) }
    func appHeadline() -> some View { modifier(AppHeadline()) }
    func appBody(color: Color = .secondary) -> some View { modifier(AppBody(color: color)) }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            a = 255
            r = ((int >> 8) & 0xF) * 17
            g = ((int >> 4) & 0xF) * 17
            b = (int & 0xF) * 17
        case 6:
            a = 255
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        case 8:
            a = (int >> 24) & 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            a = 255
            r = 0
            g = 0
            b = 0
        }
        
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
