/// A running container that publishes ports on the host.
public struct Container: Hashable, Sendable {
    public let id: String
    public let name: String
    public let image: String
    /// The Docker Compose project it belongs to, if any.
    public let composeProject: String?
    /// Host ports published by the container.
    public let publishedPorts: Set<Int>

    public init(id: String, name: String, image: String, composeProject: String?, publishedPorts: Set<Int>) {
        self.id = id
        self.name = name
        self.image = image
        self.composeProject = composeProject
        self.publishedPorts = publishedPorts
    }

    /// `postgres` for `docker.io/library/postgres:16-alpine`.
    public var imageName: String {
        let lastComponent = image.split(separator: "/").last.map(String.init) ?? image
        return lastComponent.split(separator: "@").first.map(String.init)?.split(separator: ":").first.map(String.init) ?? lastComponent
    }
}
