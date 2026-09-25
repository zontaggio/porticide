import SwiftUI

/// The "port killed" animation, driven entirely by `progress` (0...1) so the same
/// code renders live (via TimelineView) and frame by frame for the README GIF.
///
/// Timeline, as fractions of `StopEffect.duration`:
///   0.00–0.30  the teal slash strikes through the port number
///   0.18–0.60  a shockwave ring and sparks burst out of the port
///   0.20–0.55  the row fades and desaturates
///   0.60–1.00  the row collapses, pulling the rows below it up
enum StopEffect {
    static let duration: TimeInterval = 0.9

    static func progress(startedAt start: Date, now: Date) -> Double {
        min(max(now.timeIntervalSince(start) / duration, 0), 1)
    }

    /// Maps `progress` to 0...1 within the `[from, to]` window, with an ease-out curve.
    static func phase(_ progress: Double, from: Double, to: Double) -> Double {
        let t = min(max((progress - from) / (to - from), 0), 1)
        return 1 - pow(1 - t, 3)
    }
}

/// The slash drawn across the port label.
struct PortStrike: View {
    let progress: Double

    var body: some View {
        let t = StopEffect.phase(progress, from: 0, to: 0.3)
        SlashShape()
            .trim(from: 0, to: t)
            .stroke(Brand.teal, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            .shadow(color: Brand.teal.opacity(0.9), radius: 4)
            .scaleEffect(x: 1.3, y: 1.6)
            .opacity(t > 0 ? 1 - StopEffect.phase(progress, from: 0.5, to: 0.7) : 0)
            .allowsHitTesting(false)
    }
}

/// A shockwave ring and sparks bursting out of the port label. Deterministic for a given seed.
struct SparkBurst: View {
    let progress: Double
    let seed: Int
    let accent: Color

    private static let emitAt = 0.18
    private static let lifetime = 0.42 // Fraction of the effect duration.

    var body: some View {
        Canvas { context, size in
            let age = (progress - Self.emitAt) / Self.lifetime
            guard age > 0, age < 1 else { return }
            let seconds = age * Self.lifetime * StopEffect.duration
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let eased = 1 - pow(1 - age, 3)

            // Shockwave
            let ringRadius = 6 + 34 * eased
            context.opacity = (1 - age) * 0.9
            context.stroke(
                Path(ellipseIn: CGRect(x: center.x - ringRadius, y: center.y - ringRadius * 0.7, width: ringRadius * 2, height: ringRadius * 1.4)),
                with: .color(Brand.teal),
                lineWidth: 2.5 * (1 - age) + 0.5
            )

            // Sparks, biased upwards and pulled back down by gravity.
            var random = SeededRandom(seed: seed)
            let colors = [Brand.teal, accent, .white, Brand.teal, accent]
            for index in 0..<26 {
                let angle = random.next(in: (-.pi * 0.95)...(.pi * 0.15))
                let speed = random.next(in: 80...210)
                let radius = random.next(in: 1.4...3.4)
                let gravity = 320.0
                let x = center.x + cos(angle) * speed * seconds
                let y = center.y + sin(angle) * speed * seconds + 0.5 * gravity * seconds * seconds
                let shrink = 1 - age * 0.6
                let rect = CGRect(x: x - radius * shrink, y: y - radius * shrink, width: radius * shrink * 2, height: radius * shrink * 2)
                context.opacity = 1 - age * age
                context.fill(Path(ellipseIn: rect), with: .color(colors[index % colors.count]))
            }
        }
        .frame(width: 200, height: 140)
        .allowsHitTesting(false)
    }
}

/// Collapses its content's height to `fraction` of its natural height.
struct CollapseLayout: Layout {
    var fraction: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let size = child.sizeThatFits(proposal)
        return CGSize(width: size.width, height: size.height * fraction)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let child = subviews.first else { return }
        let size = child.sizeThatFits(proposal)
        child.place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(size))
    }
}

/// A tiny deterministic generator (SplitMix64), so every stop looks the same in the GIF.
struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        let unit = Double(z >> 11) / Double(1 << 53)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}
