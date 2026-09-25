/// Default ports of popular dev tools, used to hint at what an unrecognised
/// process probably is.
public enum WellKnownPorts {
    public static func service(on port: Int) -> String? {
        table[port]
    }

    private static let table: [Int: String] = [
        1313: "Hugo",
        3000: "Next.js / Rails / Grafana",
        3306: "MySQL",
        4000: "Phoenix / Jekyll",
        4200: "Angular",
        4321: "Astro",
        4566: "LocalStack",
        5000: "Flask",
        5173: "Vite",
        5432: "PostgreSQL",
        5555: "Prisma Studio",
        5601: "Kibana",
        5672: "RabbitMQ",
        6006: "Storybook",
        6379: "Redis",
        7474: "Neo4j",
        8000: "Django / Uvicorn",
        8025: "Mailpit",
        8080: "HTTP alternate",
        8081: "Metro bundler",
        8200: "Vault",
        8443: "HTTPS alternate",
        8501: "Streamlit",
        8888: "Jupyter",
        9000: "MinIO / PHP-FPM",
        9090: "Prometheus",
        9200: "Elasticsearch",
        9229: "Node.js inspector",
        11434: "Ollama",
        27017: "MongoDB",
    ]
}
