import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlencode
from urllib.request import Request, urlopen


SONAR_URL = os.environ.get(
    "SONAR_URL",
    "http://sonarqube:9000/sonar",
).rstrip("/")

SONAR_PROJECT_KEY = os.environ.get(
    "SONAR_PROJECT_KEY",
    "cloud-devops-lab-app",
)

SONAR_TOKEN = os.environ["SONAR_TOKEN"]

PORT = int(os.environ.get("EXPORTER_PORT", "9101"))


METRICS = {
    "bugs": (
        "sonar_project_bugs",
        "Number of SonarQube bugs",
    ),
    "vulnerabilities": (
        "sonar_project_vulnerabilities",
        "Number of SonarQube vulnerabilities",
    ),
    "code_smells": (
        "sonar_project_code_smells",
        "Number of SonarQube code smells",
    ),
    "security_hotspots": (
        "sonar_project_security_hotspots",
        "Number of SonarQube security hotspots",
    ),
    "open_issues": (
        "sonar_project_open_issues",
        "Number of open SonarQube issues",
    ),
    "coverage": (
        "sonar_project_coverage_percent",
        "SonarQube project coverage percentage",
    ),
    "duplicated_lines_density": (
        "sonar_project_duplicated_lines_density_percent",
        "SonarQube duplicated lines percentage",
    ),
}


def escape_label(value):
    return (
        value.replace("\\", "\\\\")
        .replace("\n", "\\n")
        .replace('"', '\\"')
    )


def get_sonar_measures():
    metric_keys = list(METRICS.keys()) + ["alert_status"]

    query = urlencode(
        {
            "component": SONAR_PROJECT_KEY,
            "metricKeys": ",".join(metric_keys),
        }
    )

    url = f"{SONAR_URL}/api/measures/component?{query}"

    request = Request(
        url,
        headers={
            "Authorization": f"Bearer {SONAR_TOKEN}",
            "Accept": "application/json",
        },
    )

    with urlopen(request, timeout=10) as response:
        payload = json.load(response)

    return {
        item["metric"]: item.get("value", "")
        for item in payload["component"].get("measures", [])
    }


def prometheus_output():
    project = escape_label(SONAR_PROJECT_KEY)

    try:
        sonar_values = get_sonar_measures()

        lines = [
            "# HELP sonar_exporter_last_scrape_success Whether the Sonar API scrape succeeded",
            "# TYPE sonar_exporter_last_scrape_success gauge",
            "sonar_exporter_last_scrape_success 1",
        ]

        for sonar_key, (prom_name, help_text) in METRICS.items():
            raw_value = sonar_values.get(sonar_key, "0")

            try:
                value = float(raw_value)
            except (TypeError, ValueError):
                value = 0.0

            lines.extend(
                [
                    f"# HELP {prom_name} {help_text}",
                    f"# TYPE {prom_name} gauge",
                    f'{prom_name}{{project="{project}"}} {value}',
                ]
            )

        quality_gate = sonar_values.get("alert_status", "ERROR")

        gate_value = 1 if quality_gate == "OK" else 0

        lines.extend(
            [
                "# HELP sonar_project_quality_gate_ok Whether the SonarQube quality gate is OK",
                "# TYPE sonar_project_quality_gate_ok gauge",
                f'sonar_project_quality_gate_ok{{project="{project}"}} {gate_value}',
            ]
        )

        return "\n".join(lines) + "\n"

    except Exception:
        return (
            "# HELP sonar_exporter_last_scrape_success "
            "Whether the Sonar API scrape succeeded\n"
            "# TYPE sonar_exporter_last_scrape_success gauge\n"
            "sonar_exporter_last_scrape_success 0\n"
        )


class Handler(BaseHTTPRequestHandler):

    def do_GET(self):

        if self.path == "/healthz":
            body = b"ok\n"

            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()

            self.wfile.write(body)
            return

        if self.path == "/metrics":
            body = prometheus_output().encode()

            self.send_response(200)
            self.send_header(
                "Content-Type",
                "text/plain; version=0.0.4; charset=utf-8",
            )
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()

            self.wfile.write(body)
            return

        self.send_response(404)
        self.end_headers()

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
