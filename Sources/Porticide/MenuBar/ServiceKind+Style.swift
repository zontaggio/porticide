import PorticideKit
import SwiftUI

extension ServiceKind {
    var symbolName: String {
        switch self {
        case .vite: "bolt.fill"
        case .nextjs: "arrowshape.turn.up.right.fill"
        case .webpack: "cube.fill"
        case .streamlit: "sparkles"
        case .django: "leaf.fill"
        case .flask: "flask.fill"
        case .uvicorn, .gunicorn: "paperplane.fill"
        case .rails: "tram.fill"
        case .postgres, .mysql, .mongodb: "cylinder.split.1x2.fill"
        case .redis: "memorychip.fill"
        case .docker: "shippingbox.fill"
        case .bun: "hare.fill"
        case .deno: "tortoise.fill"
        case .node, .python, .ruby: "chevron.left.forwardslash.chevron.right"
        case .other: "terminal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .vite: .purple
        case .nextjs: .primary
        case .webpack, .docker, .postgres: .blue
        case .streamlit, .redis, .rails: .red
        case .django, .node, .mongodb: .green
        case .flask, .other: .gray
        case .uvicorn, .gunicorn, .deno: .teal
        case .mysql: .cyan
        case .bun: .orange
        case .python: .yellow
        case .ruby: .pink
        }
    }
}
