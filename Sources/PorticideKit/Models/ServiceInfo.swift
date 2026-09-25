/// A human-friendly description of what a process is.
public struct ServiceInfo: Hashable, Sendable {
    public let displayName: String
    /// Extra context such as a version (`v5.0.2`) or a compose file.
    public let detail: String?
    /// SF Symbol name used to represent the service.
    public let iconName: String

    public init(displayName: String, detail: String? = nil, iconName: String) {
        self.displayName = displayName
        self.detail = detail
        self.iconName = iconName
    }
}
