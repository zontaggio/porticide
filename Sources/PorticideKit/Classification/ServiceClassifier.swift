import Foundation

/// Recognises common local dev servers from a process command line.
///
/// Matching is done on the file names of the executable and its arguments
/// (`/usr/local/bin/vite` → `vite`), not on raw substrings, so that e.g.
/// `bundle exec` isn't mistaken for Bun.
public enum ServiceClassifier {
    public static func classify(commandLine: String?, processName: String) -> ServiceInfo {
        let command = CommandTokens(commandLine ?? processName)

        for rule in rules where rule.matches(command) {
            return ServiceInfo(kind: rule.kind, detail: rule.detail(command))
        }
        return ServiceInfo(kind: .other, displayName: command.names.first ?? processName)
    }

    private struct Rule: Sendable {
        let kind: ServiceKind
        let matches: @Sendable (CommandTokens) -> Bool
        var detail: @Sendable (CommandTokens) -> String? = { _ in nil }
    }

    /// Ordered from most to least specific: frameworks before the runtimes that host them.
    private static let rules: [Rule] = [
        // Frameworks first: they run on top of the runtimes listed at the end.
        Rule(kind: .streamlit, matches: { $0.contains("streamlit") }, detail: \.version),
        Rule(kind: .jupyter, matches: { $0.hasPrefix("jupyter") }),
        Rule(kind: .nextjs, matches: { $0.contains("next") || $0.hasPrefix("next-server") }, detail: \.version),
        Rule(kind: .nuxt, matches: { $0.contains("nuxt") || $0.contains("nuxi") }, detail: \.version),
        Rule(kind: .astro, matches: { $0.contains("astro") }, detail: \.version),
        Rule(kind: .angular, matches: { $0.contains("ng") && $0.contains("serve") }),
        Rule(kind: .storybook, matches: { $0.contains("storybook") || $0.contains("start-storybook") }),
        Rule(kind: .vite, matches: { $0.contains("vite") || $0.contains("vite.js") }, detail: \.version),
        Rule(kind: .webpack, matches: { $0.hasPrefix("webpack") }, detail: \.version),
        Rule(kind: .django, matches: { ($0.contains("manage.py") || $0.contains("django-admin")) && $0.contains("runserver") }),
        Rule(kind: .flask, matches: { $0.contains("flask") }),
        Rule(kind: .uvicorn, matches: { $0.contains("uvicorn") || $0.contains("fastapi") }),
        Rule(kind: .gunicorn, matches: { $0.contains("gunicorn") }),
        Rule(kind: .jekyll, matches: { $0.contains("jekyll") }),
        Rule(kind: .rails, matches: { $0.contains("rails") || $0.contains("puma") }),
        Rule(kind: .hugo, matches: { $0.contains("hugo") }),
        Rule(kind: .phoenix, matches: { $0.contains("phx.server") }),
        Rule(kind: .php, matches: { $0.hasPrefix("php") }),
        // Databases and infrastructure
        Rule(kind: .postgres, matches: { $0.contains("postgres") || $0.contains("postmaster") }),
        Rule(kind: .mysql, matches: { $0.contains("mysqld") || $0.contains("mariadbd") }),
        Rule(kind: .mongodb, matches: { $0.contains("mongod") }),
        Rule(kind: .redis, matches: { $0.hasPrefix("redis-server") || $0.hasPrefix("valkey-server") }),
        Rule(kind: .elasticsearch, matches: { $0.raw.contains("org.elasticsearch") || $0.contains("elasticsearch") }),
        Rule(kind: .rabbitmq, matches: { $0.raw.contains("rabbit") && $0.contains("beam.smp") }),
        Rule(
            kind: .docker,
            matches: { $0.hasPrefix("com.docker") || $0.hasPrefix("docker") || $0.contains("vpnkit") },
            detail: { $0.value(after: ["-f", "--file"]) }
        ),
        Rule(kind: .nginx, matches: { $0.contains("nginx") || $0.raw.hasPrefix("nginx:") }),
        Rule(kind: .caddy, matches: { $0.contains("caddy") }),
        Rule(kind: .minio, matches: { $0.contains("minio") }),
        Rule(kind: .grafana, matches: { $0.hasPrefix("grafana") }),
        Rule(kind: .prometheus, matches: { $0.contains("prometheus") }),
        Rule(kind: .ollama, matches: { $0.contains("ollama") }),
        // Runtimes
        Rule(kind: .bun, matches: { $0.contains("bun") }, detail: \.version),
        Rule(kind: .deno, matches: { $0.contains("deno") }),
        Rule(kind: .node, matches: { $0.contains("node") }),
        Rule(kind: .python, matches: { $0.hasPrefix("python") }),
        Rule(kind: .ruby, matches: { $0.contains("ruby") }),
        Rule(kind: .java, matches: { $0.contains("java") }),
        Rule(kind: .dotnet, matches: { $0.contains("dotnet") }),
    ]
}

/// A command line split into whitespace-separated tokens.
private struct CommandTokens: Sendable {
    let raw: String
    let tokens: [String]
    /// Lowercased last path component of each token.
    let names: [String]

    init(_ commandLine: String) {
        raw = commandLine
        tokens = commandLine.split(whereSeparator: \.isWhitespace).map(String.init)
        names = tokens.map { ($0 as NSString).lastPathComponent.lowercased() }
    }

    func contains(_ name: String) -> Bool { names.contains(name) }

    func hasPrefix(_ prefix: String) -> Bool { names.contains { $0.hasPrefix(prefix) } }

    func value(after flags: Set<String>) -> String? {
        guard let index = tokens.firstIndex(where: flags.contains), index + 1 < tokens.count else { return nil }
        return tokens[index + 1]
    }

    /// First `vX.Y.Z` in the command line, e.g. the one in `next-server (v14.2.3)`.
    var version: String? {
        guard let match = raw.firstMatch(of: /v(\d+\.\d+\.\d+)/) else { return nil }
        return "v\(match.1)"
    }
}
