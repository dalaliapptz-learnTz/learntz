import hashlib
import io
import json

import pytest
from docx import Document
from openpyxl import Workbook
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import (
    Image as PdfImage,
    SimpleDocTemplate,
    Table,
    TableStyle,
    Paragraph,
    Spacer,
)
from PIL import Image, ImageDraw, ImageFont

from curriculum_import_worker.processor import DocumentProcessor, DocumentValidationError


def _pdf(*, blank: bool = False) -> bytes:
    stream = io.BytesIO()
    document = SimpleDocTemplate(stream, pagesize=letter)
    if blank:
        elements = [Spacer(1, 10)]
    else:
        styles = getSampleStyleSheet()
        elements = [
            Paragraph("Official Curriculum", styles["Title"]),
            Spacer(1, 12),
            Table([["Topic", "Outcome"], ["Numbers", "Count to ten"]]),
        ]
        elements[2].setStyle(TableStyle([
            ("GRID", (0, 0), (-1, -1), 1, colors.black),
        ]))
    document.build(elements)
    return stream.getvalue()


def _process(payload: bytes, name: str, content_type: str, processor=None):
    parser = processor or DocumentProcessor(ocr_function=lambda image: ("", None))
    return parser.process(
        payload,
        filename=name,
        declared_content_type=content_type,
        expected_sha256=hashlib.sha256(payload).hexdigest(),
        expected_size_bytes=len(payload),
    )


def test_pdf_extracts_page_text_tables_and_heading_candidates():
    result = _process(_pdf(), "curriculum.pdf", "application/pdf")

    assert len(result.pages) == 1
    assert "Official Curriculum" in result.pages[0]["extracted_text"]
    assert result.pages[0]["page_number"] == 1
    assert result.pages[0]["page_metadata"]["tables"][0][0] == ["Topic", "Outcome"]


def test_scanned_pdf_uses_ocr_and_records_confidence():
    processor = DocumentProcessor(ocr_function=lambda image: ("Recognized text", 0.91))

    result = _process(_pdf(blank=True), "scan.pdf", "application/pdf", processor)

    assert result.pages[0]["extraction_method"] == "ocr"
    assert result.pages[0]["ocr_confidence"] == 0.91
    assert "Recognized text" in result.pages[0]["extracted_text"]


def test_low_ocr_confidence_is_a_warning_not_an_approval():
    processor = DocumentProcessor(ocr_function=lambda image: ("Uncertain", 0.3))

    result = _process(_pdf(blank=True), "scan.pdf", "application/pdf", processor)

    assert result.pages[0]["extraction_warnings"] == ["ocr_confidence_low"]


def test_tesseract_reads_a_synthetic_scanned_pdf():
    image = Image.new("RGB", (1400, 360), "white")
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 82
    )
    draw.text((40, 100), "LEARN TZ CURRICULUM", fill="black", font=font)
    image_stream = io.BytesIO()
    image.save(image_stream, format="PNG")

    pdf_stream = io.BytesIO()
    document = SimpleDocTemplate(pdf_stream, pagesize=letter)
    document.build([
        PdfImage(io.BytesIO(image_stream.getvalue()), width=500, height=129)
    ])
    result = _process(
        pdf_stream.getvalue(),
        "scanned.pdf",
        "application/pdf",
        DocumentProcessor(ocr_languages="eng"),
    )

    assert result.pages[0]["extraction_method"] == "ocr"
    assert "LEARN" in result.pages[0]["extracted_text"].upper()


def test_csv_preserves_rows_as_logical_source_page():
    result = _process(
        b"subject,topic\nMath,Numbers\n",
        "curriculum.csv",
        "text/csv",
    )

    assert result.pages[0]["page_number"] == 1
    assert result.pages[0]["page_metadata"]["rows"] == [
        ["subject", "topic"], ["Math", "Numbers"]
    ]
    assert result.metadata["document_metadata"]["pagination"] == "logical"


def test_json_is_parsed_without_rewriting_source_fields():
    result = _process(
        json.dumps({"item_type": "topic", "text": "Original wording"}).encode(),
        "curriculum.json",
        "application/json",
    )

    assert result.pages[0]["page_metadata"]["document"]["text"] == "Original wording"


def test_docx_preserves_paragraph_styles_and_tables():
    document = Document()
    document.add_heading("Learning area", level=1)
    document.add_paragraph("Source wording")
    table = document.add_table(rows=1, cols=1)
    table.cell(0, 0).text = "Table source"
    stream = io.BytesIO()
    document.save(stream)

    result = _process(
        stream.getvalue(),
        "curriculum.docx",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    )

    assert "Source wording" in result.pages[0]["extracted_text"]
    assert result.pages[0]["page_metadata"]["paragraphs"][0]["style"].startswith("Heading")
    assert result.pages[0]["page_metadata"]["tables"] == [[["Table source"]]]


def test_xlsx_preserves_worksheet_names_and_rows():
    workbook = Workbook()
    sheet = workbook.active
    sheet.title = "Grade 1"
    sheet.append(["Topic", "Outcome"])
    sheet.append(["Counting", "Count objects"])
    stream = io.BytesIO()
    workbook.save(stream)

    result = _process(
        stream.getvalue(),
        "curriculum.xlsx",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    )

    assert result.pages[0]["page_metadata"]["sheet_name"] == "Grade 1"
    assert result.pages[0]["page_metadata"]["rows"][1] == ["Counting", "Count objects"]


def test_checksum_mismatch_is_rejected():
    payload = b"{}"

    with pytest.raises(DocumentValidationError, match="does not match"):
        DocumentProcessor().process(
            payload,
            filename="curriculum.json",
            declared_content_type="application/json",
            expected_sha256="0" * 64,
            expected_size_bytes=len(payload),
        )


def test_extension_mime_mismatch_is_rejected():
    payload = _pdf()

    with pytest.raises(DocumentValidationError, match="extension"):
        DocumentProcessor().process(
            payload,
            filename="curriculum.docx",
            declared_content_type="application/pdf",
            expected_sha256=hashlib.sha256(payload).hexdigest(),
            expected_size_bytes=len(payload),
        )


def test_page_reprocessing_keeps_original_page_number():
    extraction = _process(_pdf(), "curriculum.pdf", "application/pdf")

    assert DocumentProcessor.process_page(extraction, 1).pages[0]["page_number"] == 1
    with pytest.raises(DocumentValidationError, match="does not exist"):
        DocumentProcessor.process_page(extraction, 2)
