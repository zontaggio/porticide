/// The kinds of services Porticide knows how to recognise.
public enum ServiceKind: String, CaseIterable, Sendable {
    // Web frameworks and dev servers
    case vite, nextjs, nuxt, astro, angular, webpack, storybook
    case streamlit, jupyter, django, flask, uvicorn, gunicorn
    case rails, jekyll, hugo, phoenix, php
    // Runtimes
    case node, bun, deno, python, ruby, java, dotnet
    // Databases
    case postgres, mysql, mongodb, redis, elasticsearch
    // Infrastructure
    case docker, nginx, caddy, rabbitmq, minio, grafana, prometheus, ollama
    case other

    public enum Category: Int, CaseIterable, Sendable, Comparable {
        case web, database, infrastructure, other

        public var title: String {
            switch self {
            case .web: "Dev Servers"
            case .database: "Databases"
            case .infrastructure: "Services"
            case .other: "Other"
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public var category: Category {
        switch self {
        case .postgres, .mysql, .mongodb, .redis, .elasticsearch:
            .database
        case .docker, .nginx, .caddy, .rabbitmq, .minio, .grafana, .prometheus, .ollama:
            .infrastructure
        case .other:
            .other
        default:
            .web
        }
    }

    /// Whether the service usually answers HTTP, so it makes sense to open it in a browser.
    public var speaksHTTP: Bool {
        switch category {
        case .web, .other: true
        case .database: self == .elasticsearch
        case .infrastructure: self != .rabbitmq
        }
    }

    public var displayName: String {
        switch self {
        case .vite: "Vite"
        case .nextjs: "Next.js"
        case .nuxt: "Nuxt"
        case .astro: "Astro"
        case .angular: "Angular"
        case .webpack: "webpack"
        case .storybook: "Storybook"
        case .streamlit: "Streamlit"
        case .jupyter: "Jupyter"
        case .django: "Django"
        case .flask: "Flask"
        case .uvicorn: "Uvicorn"
        case .gunicorn: "Gunicorn"
        case .rails: "Rails"
        case .jekyll: "Jekyll"
        case .hugo: "Hugo"
        case .phoenix: "Phoenix"
        case .php: "PHP"
        case .node: "Node.js"
        case .bun: "Bun"
        case .deno: "Deno"
        case .python: "Python"
        case .ruby: "Ruby"
        case .java: "Java"
        case .dotnet: ".NET"
        case .postgres: "PostgreSQL"
        case .mysql: "MySQL"
        case .mongodb: "MongoDB"
        case .redis: "Redis"
        case .elasticsearch: "Elasticsearch"
        case .docker: "Docker"
        case .nginx: "nginx"
        case .caddy: "Caddy"
        case .rabbitmq: "RabbitMQ"
        case .minio: "MinIO"
        case .grafana: "Grafana"
        case .prometheus: "Prometheus"
        case .ollama: "Ollama"
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
