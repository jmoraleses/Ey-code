#!/usr/bin/env python3
"""
Lazy-load proxy for mlx_lm.server.

Listens on PORT immediately. On the first incoming request, starts
mlx_lm.server on PORT+10000, waits until it is ready, then proxies
all traffic transparently (including SSE/chunked streaming).

Usage:
    python lazy-mlx.py <port> <model_path>
"""

import sys
import re
import select
import socket
import subprocess
import threading
import time
import urllib.request

PORT = int(sys.argv[1])
MODEL = sys.argv[2]
BACKEND_HOST = "127.0.0.1"
BACKEND_PORT = PORT + 10000  # e.g. 8082 → 18082

_lock = threading.Lock()
_launched = False
_ready = threading.Event()
_proc = None


def _launch():
    global _proc
    _proc = subprocess.Popen(
        [
            sys.executable, "-m", "mlx_lm.server",
            "--model", MODEL,
            "--port", str(BACKEND_PORT),
            "--host", BACKEND_HOST,
        ],
        stdout=open(f"/tmp/mlx-lazy-{PORT}.log", "w"),
        stderr=subprocess.STDOUT,
    )
    for _ in range(180):
        try:
            urllib.request.urlopen(
                f"http://{BACKEND_HOST}:{BACKEND_PORT}/v1/models", timeout=2
            )
            _ready.set()
            print(f"[lazy-mlx:{PORT}] Model ready.", flush=True)
            return
        except Exception:
            time.sleep(1)
    print(f"[lazy-mlx:{PORT}] Timeout waiting for model.", flush=True)


def _ensure_launched():
    global _launched
    with _lock:
        if not _launched:
            _launched = True
            print(f"[lazy-mlx:{PORT}] First request — loading {MODEL}...", flush=True)
            threading.Thread(target=_launch, daemon=True).start()


def _pipe(src: socket.socket, dst: socket.socket, done: threading.Event):
    try:
        while not done.is_set():
            r, _, _ = select.select([src], [], [src], 1.0)
            if not r:
                continue
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        done.set()


def _read_request(sock: socket.socket) -> bytes | None:
    """Read a full HTTP request (headers + body) from the socket."""
    buf = b""
    sock.settimeout(30)
    try:
        while b"\r\n\r\n" not in buf:
            chunk = sock.recv(4096)
            if not chunk:
                return None
            buf += chunk

        header_part, body_part = buf.split(b"\r\n\r\n", 1)
        m = re.search(rb"[Cc]ontent-[Ll]ength:\s*(\d+)", header_part)
        if m:
            content_length = int(m.group(1))
            remaining = content_length - len(body_part)
            sock.settimeout(60)
            while remaining > 0:
                chunk = sock.recv(min(remaining, 65536))
                if not chunk:
                    break
                body_part += chunk
                remaining -= len(chunk)
        return header_part + b"\r\n\r\n" + body_part
    except Exception:
        return None


def _handle(client: socket.socket):
    request = _read_request(client)
    if not request:
        client.close()
        return

    _ensure_launched()

    if not _ready.wait(timeout=180):
        # Send a minimal HTTP 503 so opencode knows to retry later
        client.sendall(
            b"HTTP/1.1 503 Service Unavailable\r\n"
            b"Content-Type: text/plain\r\nContent-Length: 21\r\n\r\n"
            b"Model loading, retry.\n"
        )
        client.close()
        return

    try:
        backend = socket.create_connection((BACKEND_HOST, BACKEND_PORT), timeout=10)
    except Exception as e:
        print(f"[lazy-mlx:{PORT}] Backend connect error: {e}", flush=True)
        client.close()
        return

    backend.sendall(request)

    done = threading.Event()
    t = threading.Thread(target=_pipe, args=(backend, client, done), daemon=True)
    t.start()
    _pipe(client, backend, done)

    client.close()
    backend.close()


def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("127.0.0.1", PORT))
    server.listen(32)
    print(f"[lazy-mlx:{PORT}] Listening — will load model on first request", flush=True)

    while True:
        client, _ = server.accept()
        threading.Thread(target=_handle, args=(client,), daemon=True).start()


if __name__ == "__main__":
    main()
