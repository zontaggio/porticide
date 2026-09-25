import PorticideKit
import SwiftUI

extension ServiceKind {
    /// File name of the bundled Simple Icons logo, without extension.
    /// Run `scripts/update-logos.swift` after changing this list.
    var logoName: String? {
        switch self {
        case .vite: "vite"
        case .nextjs: "nextdotjs"
        case .nuxt: "nuxt"
        case .astro: "astro"
        case .angular: "angular"
        case .webpack: "webpack"
        case .storybook: "storybook"
        case .streamlit: "streamlit"
        case .jupyter: "jupyter"
        case .django: "django"
        case .flask: "flask"
        case .uvicorn: "fastapi"
        case .gunicorn: "gunicorn"
        case .rails: "rubyonrails"
        case .jekyll: "jekyll"
        case .hugo: "hugo"
        case .phoenix: "phoenixframework"
        case .php: "php"
        case .node: "nodedotjs"
        case .bun: "bun"
        case .deno: "deno"
        case .python: "python"
        case .ruby: "ruby"
        case .java: "openjdk"
        case .dotnet: "dotnet"
        case .postgres: "postgresql"
        case .mysql: "mysql"
        case .mongodb: "mongodb"
        case .redis: "redis"
        case .elasticsearch: "elasticsearch"
        case .docker: "docker"
        case .nginx: "nginx"
        case .caddy: "caddy"
        case .rabbitmq: "rabbitmq"
        case .minio: "minio"
        case .grafana: "grafana"
        case .prometheus: "prometheus"
        case .ollama: "ollama"
        case .other: nil
        }
    }

    /// Brand colour, from Simple Icons unless noted.
    var brandColor: Color {
        switch self {
        case .vite: Color(hex: 0x9135FF)
        case .nextjs, .ollama, .java, .deno: Color(hex: 0x111111)
        case .nuxt: Color(hex: 0x00DC82)
        case .astro: Color(hex: 0xBC52EE)
        case .angular: Color(hex: 0xDD0031) // Classic Angular red reads better than the current near-black.
        case .webpack: Color(hex: 0x8DD6F9)
        case .storybook: Color(hex: 0xFF4785)
        case .streamlit: Color(hex: 0xFF4B4B)
        case .jupyter: Color(hex: 0xF37626)
        case .django: Color(hex: 0x0C4B33)
        case .flask: Color(hex: 0x3BABC3)
        case .uvicorn: Color(hex: 0x009688)
        case .gunicorn: Color(hex: 0x499848)
        case .rails: Color(hex: 0xD30001)
        case .jekyll: Color(hex: 0xCC0000)
        case .hugo: Color(hex: 0xFF4088)
        case .phoenix: Color(hex: 0xFD4F00)
        case .php: Color(hex: 0x777BB4)
        case .node: Color(hex: 0x5FA04E)
        case .bun: Color(hex: 0xFBF0DF) // Bun's cream; Simple Icons lists black.
        case .python: Color(hex: 0x3776AB)
        case .ruby: Color(hex: 0xCC342D)
        case .dotnet: Color(hex: 0x512BD4)
        case .postgres: Color(hex: 0x4169E1)
        case .mysql: Color(hex: 0x4479A1)
        case .mongodb: Color(hex: 0x47A248)
        case .redis: Color(hex: 0xFF4438)
        case .elasticsearch: Color(hex: 0x005571)
        case .docker: Color(hex: 0x2496ED)
        case .nginx: Color(hex: 0x009639)
        case .caddy: Color(hex: 0x1F88C0)
        case .rabbitmq: Color(hex: 0xFF6600)
        case .minio: Color(hex: 0xC72E49)
        case .grafana: Color(hex: 0xF46800)
        case .prometheus: Color(hex: 0xE6522C)
        case .other: Color(hex: 0x6B7280)
        }
    }

    /// Light brand colours (webpack, Bun) need a dark glyph to stay legible.
    var usesDarkGlyph: Bool {
        self == .webpack || self == .bun
    }
}

/// Loads the bundled service logos as template images.
@MainActor
enum ServiceLogos {
    private static var cache: [String: NSImage] = [:]

    static func image(for kind: ServiceKind) -> NSImage? {
        guard let name = kind.logoName else { return nil }
        if let cached = cache[name] { return cached }
        guard let url = resourceBundle.url(forResource: name, withExtension: "pdf", subdirectory: "Logos"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        cache[name] = image
        return image
    }

    /// SwiftPM places resources in `Porticide_Porticide.bundle`. In a packaged `.app` that bundle
    /// lives in `Contents/Resources`, where `Bundle.module` does not look, so check there first.
    private static let resourceBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Porticide_Porticide", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return Bundle.module
    }()
}
