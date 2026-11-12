from __future__ import annotations

import os
import socket
import struct
from dataclasses import dataclass
from typing import Callable

from .errors import DocumentValidationError

_CHUNK_SIZE = 64 * 1024
_INSTREAM_COMMAND = b"zINSTREAM\x00"


@dataclass(frozen=True)
class ClamdScanner:
    """Streams untrusted document bytes to a ClamAV clamd daemon via INSTREAM."""

    host: str | None = None
    port: int = 3310
    socket_path: str | None = None
    timeout_seconds: float = 30.0
    required: bool = True

    @classmethod
    def from_environment(cls) -> ClamdScanner | None:
        socket_path = os.environ.get("CLAMAV_SOCKET", "").strip() or None
        host = os.environ.get("CLAMAV_HOST", "").strip() or None
        raw_port = os.environ.get("CLAMAV_PORT", "3310").strip()
        raw_timeout = os.environ.get("CLAMAV_TIMEOUT_SECONDS", "30").strip()
        required = os.environ.get("CLAMAV_REQUIRED", "true").strip().lower() in {
            "1",
            "true",
            "yes",
        }

        if not socket_path and not host:
            if required:
                raise RuntimeError(
                    "ClamAV antivirus configuration is required (set CLAMAV_HOST or CLAMAV_SOCKET)."
                )
            return None

        return cls(
            host=host,
            port=int(raw_port),
            socket_path=socket_path,
            timeout_seconds=max(1.0, float(raw_timeout)),
            required=required,
        )

    def scan_bytes(self, payload: bytes) -> None:
        """Scans payload with clamd and raises DocumentValidationError on detection."""
        try:
            response = self._send_instream(payload)
        except DocumentValidationError:
            raise
        except Exception as error:
            if self.required:
                raise RuntimeError("ClamAV antivirus scan failed.") from error
            return

        normalized = response.strip()
        if normalized.endswith("OK"):
            return
        if "FOUND" in normalized:
            raise DocumentValidationError(
                "malware_detected",
                "The uploaded file failed antivirus scanning and was rejected.",
            )
        if self.required:
            raise RuntimeError(f"Unexpected ClamAV scan response: {normalized!r}")

    def _send_instream(self, payload: bytes) -> str:
        if self.socket_path:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            target: str | tuple[str, int] = self.socket_path
        elif self.host:
            sock = socket.create_connection(
                (self.host, self.port), timeout=self.timeout_seconds
            )
            target = (self.host, self.port)
        else:
            raise RuntimeError("ClamdScanner requires either socket_path or host.")

        with sock:
            sock.settimeout(self.timeout_seconds)
            if self.socket_path:
                sock.connect(target)
            sock.sendall(_INSTREAM_COMMAND)
            view = memoryview(payload)
            for offset in range(0, len(view), _CHUNK_SIZE):
                chunk = view[offset : offset + _CHUNK_SIZE]
                sock.sendall(struct.pack("!I", len(chunk)))
                sock.sendall(chunk)
            sock.sendall(struct.pack("!I", 0))

            chunks: list[bytes] = []
            while True:
                data = sock.recv(4096)
                if not data:
                    break
                chunks.append(data)
                if b"\x00" in data or b"\n" in data:
                    break
        return b"".join(chunks).rstrip(b"\x00\r\n").decode("utf-8", errors="replace")


AntivirusScanner = Callable[[bytes], None]
