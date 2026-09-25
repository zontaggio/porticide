import SwiftUI

/// Geometry of the Porticide mark in a unit square (y pointing down). Shared by the
/// SwiftUI shapes below and mirrored in `scripts/generate-app-icon.swift`.
enum MarkGeometry {
    /// Outline of an RJ45 socket seen from the front: the body and the latch tab below it.
    static let socket: [CGPoint] = [
        CGPoint(x: 0.14, y: 0.20), CGPoint(x: 0.86, y: 0.20), CGPoint(x: 0.86, y: 0.68),
        CGPoint(x: 0.66, y: 0.68), CGPoint(x: 0.66, y: 0.84), CGPoint(x: 0.34, y: 0.84),
        CGPoint(x: 0.34, y: 0.68), CGPoint(x: 0.14, y: 0.68),
    ]
    static let cornerRadius: CGFloat = 0.06
    /// Contact slots along the top edge.
    static let slots: [CGRect] = [0.29, 0.43, 0.57, 0.71].map { CGRect(x: $0 - 0.03, y: 0.27, width: 0.06, height: 0.13) }
    /// The strike, at the same shallow angle as the one in the logo.
    static let slashStart = CGPoint(x: 0.06, y: 0.72)
    static let slashEnd = CGPoint(x: 0.94, y: 0.46)
    static let slashWidth: CGFloat = 0.1
    static let gapWidth: CGFloat = 0.2
}

struct PortSocketShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ unit: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + unit.x * rect.width, y: rect.minY + unit.y * rect.height)
        }
        let corners = MarkGeometry.socket.map(point)
        let radius = MarkGeometry.cornerRadius * rect.width

        var path = Path()
        // Start halfway along the last edge so every corner gets rounded.
        let last = corners[corners.count - 1]
        path.move(to: CGPoint(x: (last.x + corners[0].x) / 2, y: (last.y + corners[0].y) / 2))
        for index in corners.indices {
            path.addArc(tangent1End: corners[index], tangent2End: corners[(index + 1) % corners.count], radius: radius)
        }
        path.closeSubpath()

        for slot in MarkGeometry.slots {
            let frame = CGRect(
                x: rect.minX + slot.minX * rect.width, y: rect.minY + slot.minY * rect.height,
                width: slot.width * rect.width, height: slot.height * rect.height
            )
            path.addRoundedRect(in: frame, cornerSize: CGSize(width: frame.width / 2, height: frame.width / 2))
        }
        return path
    }
}

/// The strike from the logo, drawn left to right so it can be animated with `trim`.
struct SlashShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ unit: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + unit.x * rect.width, y: rect.minY + unit.y * rect.height)
        }
        var path = Path()
        path.move(to: point(MarkGeometry.slashStart))
        path.addLine(to: point(MarkGeometry.slashEnd))
        return path
    }
}

/// A port socket struck through by the teal slash, with a knockout gap like the logo.
struct PorticideMark: View {
    var socketColor: Color = .primary
    var slashColor: Color = Brand.teal
    /// 0 hides the slash, 1 draws it fully.
    var slashProgress: CGFloat = 1

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                PortSocketShape()
                    .fill(socketColor, style: FillStyle(eoFill: true))
                SlashShape()
                    .trim(from: 0, to: slashProgress)
                    .stroke(style: StrokeStyle(lineWidth: side * MarkGeometry.gapWidth, lineCap: .round))
                    .blendMode(.destinationOut)
                SlashShape()
                    .trim(from: 0, to: slashProgress)
                    .stroke(slashColor, style: StrokeStyle(lineWidth: side * MarkGeometry.slashWidth, lineCap: .round))
            }
            .compositingGroup()
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    HStack(spacing: 24) {
        PorticideMark().frame(width: 64)
        PorticideMark(slashProgress: 0.5).frame(width: 64)
        PorticideMark(socketColor: .white).frame(width: 64).padding().background(Brand.ink)
    }
    .padding()
}
