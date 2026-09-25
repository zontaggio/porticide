import Testing
@testable import PorticideKit

struct ServiceClassifierTests {
    @Test(arguments: [
        ("node /Users/me/web/node_modules/.bin/vite --port 5173", ServiceKind.vite),
        ("node /Users/me/web/node_modules/vite/bin/vite.js", .vite),
        ("next-server (v14.2.3)", .nextjs),
        ("node /Users/me/web/node_modules/.bin/next dev", .nextjs),
        ("node node_modules/.bin/webpack-dev-server", .webpack),
        ("/opt/homebrew/bin/python3.12 /opt/homebrew/bin/streamlit run app.py", .streamlit),
        ("python manage.py runserver 0.0.0.0:8000", .django),
        ("python -m flask run", .flask),
        ("/Users/me/api/.venv/bin/python3 /Users/me/api/.venv/bin/uvicorn main:app --reload", .uvicorn),
        ("puma 6.4.2 (tcp://localhost:3000) [blog]", .rails),
        ("/opt/homebrew/opt/postgresql@16/bin/postgres -D /opt/homebrew/var/postgresql@16", .postgres),
        ("/opt/homebrew/opt/redis/bin/redis-server 127.0.0.1:6379", .redis),
        ("/Applications/Docker.app/Contents/MacOS/com.docker.backend", .docker),
        ("bun run --hot src/index.ts", .bun),
        ("node server.js", .node),
        ("/usr/bin/python3 -m http.server 8080", .python),
    ])
    func recognisesService(commandLine: String, kind: ServiceKind) {
        #expect(ServiceClassifier.classify(commandLine: commandLine, processName: "irrelevant").kind == kind)
    }

    @Test func doesNotMistakeBundlerForBun() {
        let service = ServiceClassifier.classify(commandLine: "/usr/bin/ruby /usr/local/bin/bundle exec jekyll serve", processName: "ruby")
        #expect(service.kind == .ruby)
    }

    @Test func extractsVersion() {
        let service = ServiceClassifier.classify(commandLine: "next-server (v14.2.3)", processName: "node")
        #expect(service.detail == "v14.2.3")
    }

    @Test func extractsComposeFileForDocker() {
        let service = ServiceClassifier.classify(commandLine: "docker compose -f dev.yml up", processName: "docker")
        #expect(service.detail == "dev.yml")
    }

    @Test func fallsBackToExecutableName() {
        let service = ServiceClassifier.classify(commandLine: "/usr/local/bin/caddy run", processName: "caddy")
        #expect(service.kind == .other)
        #expect(service.displayName == "caddy")
    }

    @Test func usesProcessNameWithoutCommandLine() {
        #expect(ServiceClassifier.classify(commandLine: nil, processName: "redis-server").kind == .redis)
    }
}
