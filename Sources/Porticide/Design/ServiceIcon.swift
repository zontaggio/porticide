import PorticideKit
import SwiftUI

/// A service's logo on a tile in its brand colour, styled like a small app icon.
struct ServiceIcon: View {
    let kind: ServiceKind
    var size: CGFloat = 30

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
        shape
            .fill(
                LinearGradient(
                    colors: [kind.brandColor.mix(with: .white, by: 0.18), kind.brandColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(glyph.padding(size * 0.22))
            .overlay(shape.strokeBorder(.white.opacity(0.18), lineWidth: 0.5).blendMode(.plusLighter))
            .overlay(shape.strokeBorder(.black.opacity(0.08), lineWidth: 0.5))
            .frame(width: size, height: size)
            .shadow(color: kind.brandColor.opacity(0.35), radius: 2.5, y: 1)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var glyph: some View {
        let color: Color = kind.usesDarkGlyph ? Brand.ink : .white
        if let logo = ServiceLogos.image(for: kind) {
            Image(nsImage: logo)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(color)
        } else {
            Image(systemName: "terminal.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .padding(size * 0.02)
        }
    }
}

extension Color {
    /// Linear blend towards `other`, available on macOS 13 (unlike `Color.mix(with:by:)`).
    func mix(with other: Color, by fraction: Double) -> Color {
        let base = NSColor(self).usingColorSpace(.sRGB) ?? .gray
        let target = NSColor(other).usingColorSpace(.sRGB) ?? .white
        return Color(nsColor: base.blended(withFraction: fraction, of: target) ?? base)
    }
}
