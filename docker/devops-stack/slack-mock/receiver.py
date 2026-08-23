import json
from http.server import BaseHTTPRequestHandler, HTTPServer


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

        self.send_response(404)
        self.end_headers()


    def do_POST(self):

        content_length = int(
            self.headers.get("Content-Length", "0")
        )

        payload = self.rfile.read(content_length)

        print("\n===== SLACK MOCK NOTIFICATION =====")

        try:
            parsed = json.loads(payload.decode())
            print(json.dumps(parsed, indent=2))
        except Exception:
            print(payload.decode(errors="replace"))

        print("===== END NOTIFICATION =====\n")

        body = b"ok\n"

        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()

        self.wfile.write(body)


    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    HTTPServer(
        ("0.0.0.0", 8080),
        Handler,
    ).serve_forever()
