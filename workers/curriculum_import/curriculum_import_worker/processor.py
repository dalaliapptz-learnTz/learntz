from __future__ import annotations

import csv
import hashlib
import io
import json
import re
import zipfile
from dataclasses import dataclass
from typing import Any, Callable

import pdfplumber
import pypdfium2 as pdfium
import pytesseract
from docx import Document
from openpyxl import load_workbook
from PIL import Image
from pytesseract import Output

from .antivirus import AntivirusScanner
from .errors import DocumentValidationError

MAX_FILE_BYTES = 25 * 1024 * 1024
MAX_PAGES = 500
MAX_PAGE_CHARACTERS = 100_000
MAX_DOCUMENT_CHARACTERS = 3_000_000
MAX_ARCHIVE_ENTRIES = 1_000
MAX_ARCHIVE_EXPANDED_BYTES = 100 * 1024 * 1024
OCR_MIN_CONFIDENCE = 0.60
SUPPORTED_TYPES = {
    "application/pdf": ".pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ".docx",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": ".xlsx",
    "text/csv": ".csv",
    "application/json": ".json",
}


@dataclass(frozen=True)
class Extraction:
    pages: list[dict[str, Any]]
    metadata: dict[str, Any]


OcrFunction = Callable[[Image.Image], tuple[str, float | None]]


class DocumentProcessor:
    def __init__(
        self,
        *,
        ocr_languages: str = "swa+eng",
        ocr_function: OcrFunction | None = None,
        antivirus_scanner: AntivirusScanner | None = None,
    ) -> None:
        self.ocr_languages = ocr_languages
        self._ocr_function = ocr_function or self._ocr_image
        self._antivirus_scanner = antivirus_scanner

    def process(
        self,
        payload: bytes,
        *,
        filename: str,
        declared_content_type: str,
        expected_sha256: str,
        expected_size_bytes: int | None = None,
    ) -> Extraction:
        if self._antivirus_scanner is not None:
            self._antivirus_scanner(payload)
        self._validate_file(
            payload, filename, declared_content_type, expected_sha256,
            expected_size_bytes,
        )
        if declared_content_type == "application/pdf":
            result = self._pdf(payload)
        elif declared_content_type.endswith("wordprocessingml.document"):
            result = self._docx(payload)
        elif declared_content_type.endswith("spreadsheetml.sheet"):
            result = self._xlsx(payload)
        elif declared_content_type == "text/csv":
            result = self._csv(payload)
        else:
            result = self._json(payload)
        self._validate_extraction(result)
        return result

    @staticmethod
    def process_page(extraction: Extraction, page_number: int) -> Extraction:
        selected = [
            page for page in extraction.pages
            if page["page_number"] == page_number
        ]
        if not selected:
            raise DocumentValidationError(
                "page_not_found",
                "The requested page does not exist in this document.",
                page_number=page_number,
            )
        return Extraction(selected, extraction.metadata)

    @staticmethod
    def sha256(payload: bytes) -> str:
        return hashlib.sha256(payload).hexdigest()

    def _validate_file(
        self,
        payload: bytes,
        filename: str,
        content_type: str,
        expected_sha256: str,
        expected_size_bytes: int | None,
    ) -> None:
        if not payload or len(payload) > MAX_FILE_BYTES:
            raise DocumentValidationError("file_size_invalid", "File size must be between 1 byte and 25 MB.")
        if content_type not in SUPPORTED_TYPES:
            raise DocumentValidationError("unsupported_format", "The declared file format is not supported.")
        if not filename or len(filename) > 255 or "/" in filename or "\\" in filename or any(ord(char) < 32 for char in filename):
            raise DocumentValidationError("filename_invalid", "The original filename is invalid.")
        if not filename.lower().endswith(SUPPORTED_TYPES[content_type]):
            raise DocumentValidationError("extension_mismatch", "The file extension does not match the declared format.")
        if not re.fullmatch(r"[0-9a-f]{64}", expected_sha256):
            raise DocumentValidationError("checksum_invalid", "A lowercase SHA-256 checksum is required.")
        if self.sha256(payload) != expected_sha256:
            raise DocumentValidationError("checksum_mismatch", "The uploaded file does not match its registered SHA-256 checksum.")
        if expected_size_bytes is not None and len(payload) != expected_size_bytes:
            raise DocumentValidationError("file_size_mismatch", "The uploaded file does not match its registered size.")

        if content_type == "application/pdf" and not payload.startswith(b"%PDF-"):
            raise DocumentValidationError("file_signature_invalid", "The file does not have a PDF signature.")
        if content_type in {
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        }:
            self._validate_office_archive(payload, content_type)
        if content_type == "text/csv":
            try:
                payload.decode("utf-8-sig")
            except UnicodeDecodeError as error:
                raise DocumentValidationError("csv_encoding_invalid", "CSV files must be UTF-8 encoded.") from error
        if content_type == "application/json":
            try:
                json.loads(payload.decode("utf-8-sig"))
            except (UnicodeDecodeError, json.JSONDecodeError) as error:
                raise DocumentValidationError("json_invalid", "The file does not contain valid UTF-8 JSON.") from error

    @staticmethod
    def _validate_office_archive(payload: bytes, content_type: str) -> None:
        try:
            with zipfile.ZipFile(io.BytesIO(payload)) as archive:
                entries = archive.infolist()
                expanded_size = sum(entry.file_size for entry in entries)
                names = {entry.filename for entry in entries}
                if len(entries) > MAX_ARCHIVE_ENTRIES or expanded_size > MAX_ARCHIVE_EXPANDED_BYTES:
                    raise DocumentValidationError("archive_limits_exceeded", "The Office document exceeds safe archive limits.")
                required = (
                    {"[Content_Types].xml", "word/document.xml"}
                    if content_type.endswith("wordprocessingml.document")
                    else {"[Content_Types].xml", "xl/workbook.xml"}
                )
                if not required.issubset(names):
                    raise DocumentValidationError("file_signature_invalid", "The Office document package is incomplete.")
                if any(entry.filename.startswith(("/", "\\")) or ".." in entry.filename.split("/") for entry in entries):
                    raise DocumentValidationError("archive_path_invalid", "The Office document contains an unsafe archive path.")
        except zipfile.BadZipFile as error:
            raise DocumentValidationError("archive_invalid", "The Office document is not a valid ZIP package.") from error

    def _pdf(self, payload: bytes) -> Extraction:
        pages: list[dict[str, Any]] = []
        total_chars = 0
        try:
            pdf_document = pdfium.PdfDocument(payload)
            try:
                with pdfplumber.open(io.BytesIO(payload)) as pdf:
                    count = len(pdf.pages)
                    if count < 1 or count > MAX_PAGES:
                        raise DocumentValidationError("page_count_invalid", "PDFs must contain between 1 and 500 pages.")
                    if len(pdf_document) != count:
                        raise DocumentValidationError("pdf_page_count_mismatch", "PDF parsers returned inconsistent page counts.")
                    for index, page in enumerate(pdf.pages):
                        page_number = index + 1
                        text = page.extract_text(layout=False) or ""
                        tables = page.extract_tables() or []
                        method = "selectable_text"
                        confidence: float | None = None
                        warnings: list[str] = []
                        if len(text.strip()) < 25:
                            bitmap = pdf_document[index].render(scale=2.5).to_pil()
                            ocr_text, confidence = self._ocr_function(bitmap)
                            if ocr_text.strip():
                                text = f"{text}\n{ocr_text}".strip()
                                method = "ocr" if not page.extract_text(layout=False) else "mixed"
                            if confidence is None or confidence < OCR_MIN_CONFIDENCE:
                                warnings.append("ocr_confidence_low")
                        heading_lines = self._heading_candidates(page)
                        pages.append(self._page(
                            page_number, text, method,
                            metadata={"headings": heading_lines, "tables": tables},
                            confidence=confidence, warnings=warnings,
                        ))
                        total_chars += len(text)
                        if total_chars > MAX_DOCUMENT_CHARACTERS:
                            raise DocumentValidationError("document_text_limit", "The extracted PDF exceeds the text limit.")
            finally:
                pdf_document.close()
        except DocumentValidationError:
            raise
        except Exception as error:
            raise DocumentValidationError("pdf_parse_failed", "The PDF could not be safely parsed.") from error
        return Extraction(pages, {"page_count": len(pages), "document_metadata": {}})

    @staticmethod
    def _heading_candidates(page: Any) -> list[dict[str, Any]]:
        sizes = [
            char.get("size", 0)
            for char in page.chars
            if char.get("text", "").strip()
        ]
        if not sizes:
            return []
        body_size = sorted(sizes)[len(sizes) // 2]
        headings: list[dict[str, Any]] = []
        for line in page.extract_text_lines(layout=False) or []:
            text = (line.get("text") or "").strip()
            chars = [char for char in page.chars if char["top"] >= line["top"] and char["bottom"] <= line["bottom"]]
            if not text or not chars:
                continue
            size = max(char.get("size", 0) for char in chars)
            if size >= body_size * 1.25 and len(text) <= 300:
                headings.append({"text": text, "font_size": round(size, 2), "candidate": True})
        return headings[:100]

    def _ocr_image(self, image: Image.Image) -> tuple[str, float | None]:
        data = pytesseract.image_to_data(
            image, lang=self.ocr_languages, output_type=Output.DICT
        )
        words: list[str] = []
        confidence: list[float] = []
        for word, raw_score in zip(data["text"], data["conf"]):
            if word.strip():
                words.append(word)
                try:
                    score = float(raw_score)
                    if score >= 0:
                        confidence.append(score / 100)
                except (TypeError, ValueError):
                    continue
        average = sum(confidence) / len(confidence) if confidence else None
        return " ".join(words), average

    def _docx(self, payload: bytes) -> Extraction:
        try:
            document = Document(io.BytesIO(payload))
            paragraphs = [
                {"text": paragraph.text, "style": paragraph.style.name}
                for paragraph in document.paragraphs
                if paragraph.text.strip()
            ]
            tables = [
                [[cell.text for cell in row.cells] for row in table.rows]
                for table in document.tables
            ]
            text = "\n".join(item["text"] for item in paragraphs)
            return Extraction(
                [self._page(1, text, "structured_data", metadata={"paragraphs": paragraphs, "tables": tables})],
                {"page_count": 1, "document_metadata": {"pagination": "logical", "title": document.core_properties.title}},
            )
        except Exception as error:
            raise DocumentValidationError("docx_parse_failed", "The DOCX document could not be safely parsed.") from error

    def _xlsx(self, payload: bytes) -> Extraction:
        pages: list[dict[str, Any]] = []
        try:
            workbook = load_workbook(io.BytesIO(payload), read_only=True, data_only=False)
            if not workbook.sheetnames or len(workbook.sheetnames) > MAX_PAGES:
                raise DocumentValidationError("sheet_count_invalid", "XLSX must contain between 1 and 500 worksheets.")
            for page_number, sheet in enumerate(workbook.worksheets, start=1):
                rows = []
                for row_index, row in enumerate(sheet.iter_rows(values_only=True), start=1):
                    if row_index > 10000:
                        raise DocumentValidationError("worksheet_row_limit", "A worksheet exceeds the 10,000 row limit.", page_number=page_number)
                    values = ["" if value is None else str(value) for value in row]
                    if any(value.strip() for value in values):
                        rows.append(values)
                text = "\n".join("\t".join(row) for row in rows)
                pages.append(self._page(page_number, text, "structured_data", metadata={"sheet_name": sheet.title, "rows": rows}))
            workbook.close()
        except DocumentValidationError:
            raise
        except Exception as error:
            raise DocumentValidationError("xlsx_parse_failed", "The XLSX document could not be safely parsed.") from error
        return Extraction(pages, {"page_count": len(pages), "document_metadata": {"sheet_names": [page["page_metadata"]["sheet_name"] for page in pages]}})

    def _csv(self, payload: bytes) -> Extraction:
        try:
            rows = list(
                csv.reader(
                    io.StringIO(payload.decode("utf-8-sig")),
                    strict=True,
                )
            )
        except (UnicodeDecodeError, csv.Error) as error:
            raise DocumentValidationError("csv_parse_failed", "The CSV document could not be safely parsed.") from error
        if not rows or len(rows) > 10_000:
            raise DocumentValidationError("csv_row_limit", "CSV must contain between 1 and 10,000 rows.")
        text = "\n".join("\t".join(row) for row in rows)
        return Extraction(
            [self._page(1, text, "structured_data", metadata={"rows": rows})],
            {"page_count": 1, "document_metadata": {"row_count": len(rows), "pagination": "logical"}},
        )

    def _json(self, payload: bytes) -> Extraction:
        try:
            document = json.loads(payload.decode("utf-8-sig"))
            text = json.dumps(document, ensure_ascii=False, indent=2)
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise DocumentValidationError("json_parse_failed", "The JSON document could not be safely parsed.") from error
        return Extraction(
            [self._page(1, text, "structured_data", metadata={"document": document})],
            {"page_count": 1, "document_metadata": {"pagination": "logical"}},
        )

    @staticmethod
    def _page(
        page_number: int,
        text: str,
        method: str,
        *,
        metadata: dict[str, Any],
        confidence: float | None = None,
        warnings: list[str] | None = None,
    ) -> dict[str, Any]:
        return {
            "page_number": page_number,
            "extracted_text": text,
            "extraction_method": method,
            "ocr_confidence": confidence,
            "page_metadata": metadata,
            "extraction_warnings": warnings or [],
        }

    @staticmethod
    def _validate_extraction(extraction: Extraction) -> None:
        if not extraction.pages or len(extraction.pages) > MAX_PAGES:
            raise DocumentValidationError("page_count_invalid", "The extracted document has an invalid page count.")
        total = 0
        for expected, page in enumerate(extraction.pages, start=1):
            text = page["extracted_text"]
            if page["page_number"] != expected or len(text) > MAX_PAGE_CHARACTERS:
                raise DocumentValidationError("page_output_invalid", "The extraction produced invalid page output.", page_number=expected)
            total += len(text)
        if total > MAX_DOCUMENT_CHARACTERS:
            raise DocumentValidationError("document_text_limit", "The extracted document exceeds the text limit.")
