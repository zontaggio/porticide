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
        ("node /Users/me/site/node_modules/.bin/astro dev", .astro),
        ("node /Users/me/app/node_modules/.bin/ng serve", .angular),
        ("/opt/homebrew/bin/python3 /opt/homebrew/bin/jupyter-lab", .jupyter),
        ("/opt/homebrew/opt/ollama/bin/ollama serve", .ollama),
        ("nginx: master process /opt/homebrew/opt/nginx/bin/nginx -g daemon off;", .nginx),
        ("/opt/homebrew/opt/mysql/bin/mysqld --basedir=/opt/homebrew/opt/mysql", .mysql),
        ("bundle exec jekyll serve --livereload", .jekyll),
        ("node server.js", .node),
        ("/usr/bin/python3 -m http.server 8080", .python),
    ])
    func recognisesService(commandLine: String, kind: ServiceKind) {
        #expect(ServiceClassifier.classify(commandLine: commandLine, processName: "irrelevant").kind == kind)
    }

    @Test func doesNotMistakeBundlerForBun() {
        let service = ServiceClassifier.classify(commandLine: "/usr/bin/ruby /usr/local/bin/bundle exec rackup", processName: "ruby")
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
        let service = ServiceClassifier.classify(commandLine: "/opt/homebrew/bin/mailpit --smtp 0.0.0.0:1025", processName: "mailpit")
        #expect(service.kind == .other)
        #expect(service.displayName == "mailpit")
    }

    @Test func usesProcessNameWithoutCommandLine() {
        #expect(ServiceClassifier.classify(commandLine: nil, processName: "redis-server").kind == .redis)
    }

    @Test func groupsKindsIntoCategories() {
        #expect(ServiceKind.vite.category == .web)
        #expect(ServiceKind.postgres.category == .database)
        #expect(ServiceKind.docker.category == .infrastructure)
        #expect(!ServiceKind.redis.speaksHTTP)
    }
}
