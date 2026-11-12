from __future__ import annotations

import logging
import os
import threading
import time

from . import __version__
from .antivirus import ClamdScanner
from .client import SupabaseWorkerClient
from .processor import DocumentProcessor, DocumentValidationError


logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("learntz.curriculum.worker")


def main() -> None:
    client = SupabaseWorkerClient.from_environment()
    scanner = ClamdScanner.from_environment()
    processor = DocumentProcessor(
        ocr_languages=os.environ.get("OCR_LANGUAGES", "swa+eng"),
        antivirus_scanner=scanner.scan_bytes if scanner is not None else None,
    )
    poll_interval = max(1, int(os.environ.get("POLL_INTERVAL_SECONDS", "5")))
    logger.info("Starting curriculum import worker version=%s", __version__)
    try:
        while True:
            try:
                job = client.claim()
                if job is None:
                    time.sleep(poll_interval)
                    continue
                _process_job(client, processor, job)
            except Exception:
                logger.exception("Worker polling or processing request failed")
                time.sleep(poll_interval)
    finally:
        client.close()


def _process_job(client: SupabaseWorkerClient, processor: DocumentProcessor, job: dict) -> None:
    job_id = job.get("id")
    page_number = job.get("processing_page_number")
    stop_heartbeat = threading.Event()
    heartbeat_error: list[Exception] = []

    def renew_lease() -> None:
        while not stop_heartbeat.wait(60):
            try:
                client.renew_lease(job_id)
            except Exception as error:
                heartbeat_error.append(error)
                return

    heartbeat = threading.Thread(target=renew_lease, daemon=True)
    heartbeat.start()
    try:
        payload = client.download(job["storage_bucket"], job["storage_object_path"])
        extraction = processor.process(
            payload,
            filename=job["original_filename"],
            declared_content_type=job["declared_content_type"],
            expected_sha256=job["file_sha256"],
            expected_size_bytes=job["file_size_bytes"],
        )
        if page_number is not None:
            extraction = processor.process_page(extraction, page_number)
        if heartbeat_error:
            raise RuntimeError("The import processing lease was lost.") from heartbeat_error[0]
        metadata = {
            **extraction.metadata,
            "engine": "learntz-curriculum-worker",
            "engine_version": __version__,
            "detected_content_type": job["declared_content_type"],
        }
        client.complete(job_id, extraction.pages, metadata)
        logger.info("Processed curriculum import job=%s pages=%s", job_id, len(extraction.pages))
    except DocumentValidationError as error:
        logger.warning(
            "Document rejected job=%s code=%s page=%s",
            job_id, error.code, error.page_number,
        )
        client.fail(
            job_id, str(error), error.code,
            retryable=False, page_number=error.page_number,
        )
    except Exception:
        logger.exception("Document processing failed job=%s", job_id)
        client.fail(
            job_id, "Document processing failed; see restricted worker logs.",
            "processing_failed", retryable=True, page_number=page_number,
        )
    finally:
        stop_heartbeat.set()
        heartbeat.join(timeout=5)


if __name__ == "__main__":
    main()
