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
        Rule(kind: .streamlit, matches: { $0.contains("streamlit") }, detail: \.version),
        Rule(kind: .nextjs, matches: { $0.contains("next") || $0.hasPrefix("next-server") }, detail: \.version),
        Rule(kind: .vite, matches: { $0.contains("vite") || $0.contains("vite.js") }, detail: \.version),
        Rule(kind: .webpack, matches: { $0.hasPrefix("webpack") }, detail: \.version),
        Rule(kind: .django, matches: { ($0.contains("manage.py") || $0.contains("django-admin")) && $0.contains("runserver") }),
        Rule(kind: .flask, matches: { $0.contains("flask") }),
        Rule(kind: .uvicorn, matches: { $0.contains("uvicorn") }),
        Rule(kind: .gunicorn, matches: { $0.contains("gunicorn") }),
        Rule(kind: .rails, matches: { $0.contains("rails") || $0.contains("puma") }),
        Rule(kind: .postgres, matches: { $0.contains("postgres") || $0.contains("postmaster") }),
        Rule(kind: .redis, matches: { $0.hasPrefix("redis-server") }),
        Rule(kind: .mysql, matches: { $0.contains("mysqld") }),
        Rule(kind: .mongodb, matches: { $0.contains("mongod") }),
        Rule(
            kind: .docker,
            matches: { $0.hasPrefix("com.docker") || $0.hasPrefix("docker") || $0.contains("vpnkit") },
            detail: { $0.value(after: ["-f", "--file"]) }
        ),
        Rule(kind: .bun, matches: { $0.contains("bun") }, detail: \.version),
        Rule(kind: .deno, matches: { $0.contains("deno") }),
        Rule(kind: .node, matches: { $0.contains("node") }),
        Rule(kind: .python, matches: { $0.hasPrefix("python") }),
        Rule(kind: .ruby, matches: { $0.contains("ruby") }),
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
