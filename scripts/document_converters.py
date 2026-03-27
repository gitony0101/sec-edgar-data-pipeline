"""
Document conversion helpers for SEC filing content.
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Optional

import markdownify
from pypdf import PdfReader


def html_to_markdown(html_text: str) -> str:
    """
    Convert HTML or XML-like content to Markdown.
    """
    return markdownify.markdownify(
        html_text,
        strip=["script", "style"],
        heading_style="ATX",
    )


def html_file_to_markdown(file_path: Path) -> str:
    return html_to_markdown(Path(file_path).read_text(encoding="utf-8", errors="ignore"))


def pdf_to_markdown(file_path: Path) -> str:
    """
    Extract plain text from a PDF and return Markdown-compatible text.
    """
    reader = PdfReader(str(file_path))
    chunks = []
    for page in reader.pages:
        chunks.append(page.extract_text() or "")
    return "\n\n---\n\n".join(chunks).strip()


def txt_to_markdown(file_path: Path) -> str:
    return Path(file_path).read_text(encoding="utf-8", errors="ignore")


def convert_local_file_to_markdown(file_path: Path) -> str:
    """
    Convert a local file to Markdown based on file extension.
    """
    suffix = Path(file_path).suffix.lower()
    if suffix in {".htm", ".html", ".xml"}:
        return html_file_to_markdown(file_path)
    if suffix == ".pdf":
        return pdf_to_markdown(file_path)
    if suffix in {".txt", ".md"}:
        return txt_to_markdown(file_path)
    raise ValueError(f"Unsupported file type: {suffix}")


def save_markdown(markdown_text: str, output_path: Path) -> Path:
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(markdown_text, encoding="utf-8")
    return output_path


def markdown_to_docx(markdown_text: str, output_path: Path) -> Path:
    """
    Convert Markdown text to DOCX using pypandoc.
    """
    import pypandoc

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temp_md = output_path.with_suffix(".tmp.md")
    temp_md.write_text(markdown_text, encoding="utf-8")
    pypandoc.convert_file(str(temp_md), "docx", outputfile=str(output_path))
    temp_md.unlink(missing_ok=True)
    return output_path


def try_ocr_pdf(input_pdf: Path, output_pdf: Optional[Path] = None, language: str = "eng") -> Path:
    """
    Run OCR on a PDF using ocrmypdf if the executable is available.
    """
    input_pdf = Path(input_pdf)
    output_pdf = Path(output_pdf) if output_pdf else input_pdf.with_name(f"{input_pdf.stem}_ocr{input_pdf.suffix}")
    command = [
        "ocrmypdf",
        "-f",
        "-l",
        language,
        str(input_pdf),
        str(output_pdf),
    ]
    subprocess.run(command, check=True)
    return output_pdf
