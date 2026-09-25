/// The kinds of services Porticide knows how to recognise.
public enum ServiceKind: String, CaseIterable, Sendable {
    // Frameworks and dev servers
    case vite, nextjs, webpack, streamlit, django, flask, uvicorn, gunicorn, rails
    // Databases and infrastructure
    case postgres, redis, mysql, mongodb, docker
    // Generic runtimes
    case node, bun, deno, python, ruby
    case other

    public var displayName: String {
        switch self {
        case .vite: "Vite"
        case .nextjs: "Next.js"
        case .webpack: "webpack"
        case .streamlit: "Streamlit"
        case .django: "Django"
        case .flask: "Flask"
        case .uvicorn: "Uvicorn"
        case .gunicorn: "Gunicorn"
        case .rails: "Rails"
        case .postgres: "PostgreSQL"
        case .redis: "Redis"
        case .mysql: "MySQL"
        case .mongodb: "MongoDB"
        case .docker: "Docker"
        case .node: "Node.js"
        case .bun: "Bun"
        case .deno: "Deno"
        case .python: "Python"
        case .ruby: "Ruby"
        case .other: "Process"
        }
    }
}

/// A human-friendly description of what a process is.
public struct ServiceInfo: Hashable, Sendable {
    public let kind: ServiceKind
    public let displayName: String
    /// Extra context such as a version (`v5.0.2`) or a compose file.
    public let detail: String?

    public init(kind: ServiceKind, displayName: String? = nil, detail: String? = nil) {
        self.kind = kind
        self.displayName = displayName ?? kind.displayName
        self.detail = detail
    }
}
