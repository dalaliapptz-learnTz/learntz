# Curriculum import worker

This self-hosted worker processes private documents only after the database has
verified the source identity and independently reviewed its usage rights. It
uses the Supabase service-role key only in the worker process; never place that
key in Flutter, browser code, source control, or an image layer. No hosted
deployment or TIE document ingestion is authorized by this package.

## Supported input

The worker accepts PDF, DOCX, XLSX, CSV, and JSON, with a 25 MiB upload cap.
It checks the registered SHA-256, filename/extension, content signature or
container structure, UTF-8 where applicable, page/sheet limits, ZIP expansion
limits, and output character limits. The database/storage bucket allowlist and
worker both validate inputs; neither a file extension nor browser MIME type is
trusted as proof of format.

PDF processing extracts selectable text and tables page by page. Pages with
little selectable text are rendered with PDFium and OCR'd with Tesseract using
Swahili and English by default. Per-page method, engine version, average word
confidence, candidate headings, tables, and warnings are returned. OCR scores
are triage signals only; they do not establish curriculum accuracy. DOCX/XLSX
pagination is logical (paragraph/table or worksheet), not a claim about
printed-page layout. CSV/JSON have one logical source page.

No automatic semantic curriculum classification or generated official
wording is performed. Editors create/correct structured candidate items from
source-linked extracted pages; reviewers decide whether candidates faithfully
represent the document. PDF heading candidates are layout heuristics, not
validated section semantics. Similarity matches are review suggestions and
are never automatically merged.

## Local development

Build the image from this directory:

```sh
docker build -t learntz-curriculum-import-worker .
```

Run the processor test suite from this directory:

```sh
docker build -f Dockerfile.test -t learntz-curriculum-import-worker-test .
docker run --rm learntz-curriculum-import-worker-test
```

Run one or more worker replicas on the private network with:

- `SUPABASE_URL`: internal Supabase API URL reachable from the worker.
- `SUPABASE_SERVICE_ROLE_KEY`: the local or deployment service-role secret,
  injected by the deployment secret manager at runtime.
- `CLAMAV_HOST` / `CLAMAV_SOCKET` and `CLAMAV_PORT` (default `3310`): ClamAV
  `clamd` endpoint used for `INSTREAM` malware scanning before extraction.
- `CLAMAV_REQUIRED` (default `true`): fail closed if ClamAV is unconfigured or
  unreachable.
- Optional `POLL_INTERVAL_SECONDS` and `OCR_LANGUAGES` (default `swa+eng`).

Deployment security manifests are provided in `docker-compose.yml` (worker +
`clamav` daemon container) and `k8s/worker-pod.yaml` (non-root `UID 10001`,
`readOnlyRootFilesystem: true`, `drop ALL` capabilities, and `1Gi` worker memory
limit). Keep service-role credentials out of build arguments and logs, and
restrict worker egress to the Supabase API/storage endpoints and ClamAV daemon.

The database lease is renewed during processing. Jobs are claimed with
`FOR UPDATE SKIP LOCKED`, have bounded retries, and become recoverable after a
worker lease expires. Keep worker replicas private; the claim/complete/fail
RPCs are granted only to the `service_role`.

## Limits and operations

ClamAV scanning validates incoming payloads prior to extraction when configured;
the worker still does not provide password-protected document support,
handwritten-text recognition, or legal review. Treat a parser/OCR failure as a
reviewable job error; do not silently substitute empty text. Before production,
ensure ClamAV signature database updates, retention and backup policies,
monitoring/alerts, secret rotation, resource sizing, and regional
data-residency review are configured. Retain the source only as permitted by the
document's recorded rights.
