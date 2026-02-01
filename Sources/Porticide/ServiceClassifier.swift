import Foundation

struct ServiceInfo: Hashable {
    let displayName: String
    let detail: String?
    let iconName: String
}

enum ServiceClassifier {
    static func classify(commandLine: String?) -> ServiceInfo {
        guard let commandLine else {
            return ServiceInfo(displayName: "Unknown", detail: nil, iconName: "questionmark")
        }

        let lower = commandLine.lowercased()

        if lower.contains("streamlit") {
            return ServiceInfo(displayName: "streamlit", detail: extractVersion(from: commandLine), iconName: "sparkles")
        }
        if lower.contains("next dev") || lower.contains("next-server") {
            return ServiceInfo(displayName: "next-server", detail: extractVersion(from: commandLine), iconName: "arrowshape.turn.up.right")
        }
        if lower.contains("vite") {
            return ServiceInfo(displayName: "vite-dev-server", detail: extractVersion(from: commandLine), iconName: "bolt.fill")
        }
        if lower.contains("webpack") {
            return ServiceInfo(displayName: "webpack-hot-reload", detail: extractVersion(from: commandLine), iconName: "flame.fill")
        }
        if lower.contains("django") && lower.contains("runserver") {
            return ServiceInfo(displayName: "django-runserver", detail: nil, iconName: "leaf.fill")
        }
        if lower.contains("flask") {
            return ServiceInfo(displayName: "flask", detail: nil, iconName: "drop.fill")
        }
        if lower.contains("uvicorn") {
            return ServiceInfo(displayName: "uvicorn", detail: nil, iconName: "paperplane.fill")
        }
        if lower.contains("gunicorn") {
            return ServiceInfo(displayName: "gunicorn", detail: nil, iconName: "shield.fill")
        }
        if lower.contains("bun") {
            return ServiceInfo(displayName: "bun", detail: extractVersion(from: commandLine), iconName: "hare.fill")
        }
        if lower.contains("docker") {
            if let file = extractFlagValue(from: commandLine, flags: ["-f", "--file"]) {
                return ServiceInfo(displayName: "docker", detail: file, iconName: "shippingbox.fill")
            }
            return ServiceInfo(displayName: "docker", detail: nil, iconName: "shippingbox.fill")
        }
        if lower.contains("node") {
            return ServiceInfo(displayName: "node", detail: nil, iconName: "chevron.left.slash.chevron.right")
        }
        if lower.contains("python") {
            return ServiceInfo(displayName: "python", detail: nil, iconName: "chevron.left.slash.chevron.right")
        }

        return ServiceInfo(displayName: commandLine.components(separatedBy: " ").first ?? "process", detail: nil, iconName: "terminal")
    }

    private static func extractVersion(from commandLine: String) -> String? {
        let pattern = "v(\\d+\\.\\d+\\.\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(commandLine.startIndex..<commandLine.endIndex, in: commandLine)
        guard let match = regex.firstMatch(in: commandLine, options: [], range: range),
              let versionRange = Range(match.range(at: 1), in: commandLine) else { return nil }
        return "v\(commandLine[versionRange])"
    }

    private static func extractFlagValue(from commandLine: String, flags: [String]) -> String? {
        let parts = commandLine.split(separator: " ").map(String.init)
        for (index, part) in parts.enumerated() {
            if flags.contains(part), index + 1 < parts.count {
                return parts[index + 1]
            }
        }
        return nil
    }
}
// Improve ServiceClassifier detection accuracy
