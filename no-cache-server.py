from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import os

os.chdir("dist")

class NoCache(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

server = ThreadingHTTPServer(("0.0.0.0", 3000), NoCache)
print("MauriMesh no-cache static server running on 0.0.0.0:3000")
server.serve_forever()
