#!/usr/bin/env python3
"""Expose the fixed Sub2API deploy command over a local Unix socket."""

import http.server
import json
import logging
import os
from pathlib import Path
import re
import socketserver
import subprocess
import threading

UPDATER = "/usr/local/sbin/sub2api-maintained-upgrade"
SOCKET = Path("/run/sub2api-maintained-panel/upgrade.sock")
APP_GID = 1000
CHECK_INTERVAL = 180
RELEASE = re.compile(r"sub2api-patched-v(\d+\.\d+\.\d+)-([a-f0-9]{12})")


class UpgradeState:
    def __init__(self):
        self.lock = threading.Lock()
        self.state = "checking"
        self.current = ""
        self.latest = ""
        self.selected = ""
        self.accepting = False
        self.generation = 0

    def snapshot_locked(self):
        return {
            "state": self.state,
            "current_image": self.current,
            "latest_release": self.latest,
            "update_available": self.accepting and self.current != self.selected,
        }

    def status(self):
        with self.lock:
            return self.snapshot_locked()

    def refresh(self):
        with self.lock:
            if self.state == "running":
                return
            generation = self.generation
        try:
            result = subprocess.run(
                [UPDATER, "--check"], text=True, stdout=subprocess.PIPE, check=True, timeout=35
            )
            fields = dict(line.split(": ", 1) for line in result.stdout.splitlines() if ": " in line)
            current = fields["Current"]
            latest = fields["Latest tested release"]
            selected = fields["Selected"]
            match = RELEASE.fullmatch(latest)
            if not match or selected != f"local/sub2api:patched-{match[1]}-{match[2]}" or not current:
                raise ValueError("Unexpected deploy check output")
        except (OSError, subprocess.SubprocessError, KeyError, ValueError):
            logging.exception("Could not check Sub2API releases")
            with self.lock:
                if self.state != "running" and generation == self.generation:
                    self.state = "unavailable"
                    self.accepting = False
            return
        with self.lock:
            if self.state != "running" and generation == self.generation:
                if self.state not in {"succeeded", "failed"} or self.latest != latest:
                    self.state = "ready"
                self.current = current
                self.latest = latest
                self.selected = selected
                self.accepting = True

    def start(self, release):
        with self.lock:
            if self.state == "running" and release == self.latest:
                return 202, self.snapshot_locked()
            if (
                not self.accepting
                or self.current == self.selected
                or release != self.latest
            ):
                return 409, self.snapshot_locked()
            self.generation += 1
            self.state = "running"
            self.accepting = False
            threading.Thread(target=self.install, args=(release, self.selected), daemon=True).start()
            return 202, self.snapshot_locked()

    def install(self, release, image):
        try:
            subprocess.run([UPDATER, "--apply", release], check=True)
        except (OSError, subprocess.SubprocessError):
            logging.exception("Sub2API upgrade failed")
            with self.lock:
                self.state = "failed"
        else:
            with self.lock:
                self.current = image
                self.state = "succeeded"
        self.refresh()

    def check_releases(self):
        pause = threading.Event()
        while True:
            self.refresh()
            pause.wait(CHECK_INTERVAL)


class UpgradeServer(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True

    def get_request(self):
        sock, address = super().get_request()
        sock.settimeout(4)
        return sock, address


class Handler(http.server.BaseHTTPRequestHandler):
    def reply(self, status, data):
        payload = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def address_string(self):
        return "local"

    def log_request(self, code="-", size="-"):
        if self.command != "GET":
            super().log_request(code, size)

    def do_GET(self):
        if self.path != "/status":
            self.reply(404, {})
            return
        self.reply(200, self.server.upgrades.status())

    def do_POST(self):
        if self.path != "/apply":
            self.reply(404, {})
            return
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= 512:
                raise ValueError("Invalid request size")
            data = json.loads(self.rfile.read(size))
            if not isinstance(data, dict) or set(data) != {"release"}:
                raise ValueError("Invalid request body")
            release = data["release"]
            if not isinstance(release, str) or not RELEASE.fullmatch(release):
                raise ValueError("Invalid release")
        except (ValueError, OSError):
            self.reply(400, {})
            return
        code, status = self.server.upgrades.start(release)
        self.reply(code, status)


def main():
    logging.basicConfig(level=logging.INFO)
    SOCKET.unlink(missing_ok=True)
    os.umask(0o117)
    with UpgradeServer(str(SOCKET), Handler) as server:
        os.chown(SOCKET, 0, APP_GID)
        os.chmod(SOCKET, 0o660)
        os.umask(0o077)
        server.upgrades = UpgradeState()
        threading.Thread(target=server.upgrades.check_releases, daemon=True).start()
        server.serve_forever()


if __name__ == "__main__":
    main()
