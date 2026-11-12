import os
import socketserver
import struct
import threading
import unittest
from unittest.mock import patch

from curriculum_import_worker.antivirus import ClamdScanner
from curriculum_import_worker.errors import DocumentValidationError

EICAR_TEST_STRING = (
    b"X5O!P%@AP[4\\PZX54(P^)7CC)7}$"
    b"EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"
)


class _MockClamdHandler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        command = b""
        while not command.endswith(b"\x00"):
            byte = self.request.recv(1)
            if not byte:
                return
            command += byte

        if command != b"zINSTREAM\x00":
            self.request.sendall(b"UNKNOWN COMMAND\x00")
            return

        payload = bytearray()
        while True:
            header = self._recv_exact(4)
            if not header:
                return
            (length,) = struct.unpack("!I", header)
            if length == 0:
                break
            chunk = self._recv_exact(length)
            if not chunk:
                return
            payload.extend(chunk)

        if EICAR_TEST_STRING in bytes(payload):
            self.request.sendall(b"stream: Eicar-Signature FOUND\x00")
        else:
            self.request.sendall(b"stream: OK\x00")

    def _recv_exact(self, size: int) -> bytes:
        buf = bytearray()
        while len(buf) < size:
            data = self.request.recv(size - len(buf))
            if not data:
                return b""
            buf.extend(data)
        return bytes(buf)


class _ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True


class TestClamdScanner(unittest.TestCase):
    def setUp(self) -> None:
        self.server = _ThreadedTCPServer(("127.0.0.1", 0), _MockClamdHandler)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self) -> None:
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)

    def test_clean_payload_passes_clamd_scan(self) -> None:
        scanner = ClamdScanner(host="127.0.0.1", port=self.port, required=True)
        scanner.scan_bytes(b'{"subject": "Mathematics", "topic": "Numbers"}')

    def test_eicar_payload_raises_malware_detected_validation_error(self) -> None:
        scanner = ClamdScanner(host="127.0.0.1", port=self.port, required=True)
        with self.assertRaises(DocumentValidationError) as ctx:
            scanner.scan_bytes(EICAR_TEST_STRING)
        self.assertEqual(ctx.exception.code, "malware_detected")

    def test_required_scanner_fails_closed_when_daemon_unreachable(self) -> None:
        scanner = ClamdScanner(host="127.0.0.1", port=1, timeout_seconds=1.0, required=True)
        with self.assertRaises(RuntimeError):
            scanner.scan_bytes(b"%PDF-1.4")

    def test_from_environment_requires_clamav_config_by_default(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(RuntimeError):
                ClamdScanner.from_environment()

        with patch.dict(os.environ, {"CLAMAV_HOST": "clamav", "CLAMAV_PORT": "3310"}, clear=True):
            scanner = ClamdScanner.from_environment()
            self.assertIsNotNone(scanner)
            self.assertEqual(scanner.host, "clamav")
            self.assertEqual(scanner.port, 3310)
            self.assertTrue(scanner.required)
