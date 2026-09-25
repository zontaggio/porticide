import Testing
@testable import PorticideKit

struct ContainersTests {
    @Test func parsesContainersWithPublishedPorts() {
        let output = """
        a9287d9546d7\tcayuan-dev-admin-web\tcayuan-dev:latest\t3002-3003/tcp, 5174/tcp, 0.0.0.0:5173->5173/tcp, [::]:5173->5173/tcp\tcayuan-dev
        0bfbdd0916f5\tcayuan-dev-worker\tcayuan-dev:latest\t3002-3003/tcp, 5173-5174/tcp\tcayuan-dev
        f69cfaf5af63\tscratch-postgres\tpostgres:16-alpine\t0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp\t
        """

        #expect(Containers.parse(output) == [
            Container(id: "a9287d9546d7", name: "cayuan-dev-admin-web", image: "cayuan-dev:latest", composeProject: "cayuan-dev", publishedPorts: [5173]),
            Container(id: "f69cfaf5af63", name: "scratch-postgres", image: "postgres:16-alpine", composeProject: nil, publishedPorts: [5433]),
        ])
    }

    @Test(arguments: [
        ("0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp", Set([5433])),
        ("127.0.0.1:8000-8002->8000-8002/tcp", Set([8000, 8001, 8002])),
        ("3002-3003/tcp, 5173/tcp", Set<Int>()),
        ("", Set<Int>()),
    ])
    func extractsHostPorts(column: String, ports: Set<Int>) {
        #expect(Containers.publishedPorts(column) == ports)
    }

    @Test(arguments: [
        ("postgres:16-alpine", "postgres"),
        ("docker.io/library/redis:7", "redis"),
        ("ghcr.io/acme/api@sha256:abc", "api"),
        ("cayuan-dev:latest", "cayuan-dev"),
    ])
    func extractsImageName(image: String, name: String) {
        #expect(Container(id: "", name: "", image: image, composeProject: nil, publishedPorts: []).imageName == name)
    }

    @Test(arguments: [
        ("postgres:16-alpine", ServiceKind.postgres),
        ("redis:7", .redis),
        ("mongo:7", .mongodb),
        ("nginx:alpine", .nginx),
        ("cayuan-dev:latest", .docker),
    ])
    func classifiesContainersByImage(image: String, kind: ServiceKind) {
        let container = Container(id: "1", name: "app-db", image: image, composeProject: nil, publishedPorts: [5432])
        let service = ServiceClassifier.classify(container: container)
        #expect(service.kind == kind)
        #expect(service.displayName == "app-db")
        #expect(service.detail == image)
    }

    @Test func recognisesRuntimeProcesses() {
        #expect(Containers.isRuntime("OrbStack"))
        #expect(Containers.isRuntime("com.docker.backend"))
        #expect(!Containers.isRuntime("node"))
    }
}
