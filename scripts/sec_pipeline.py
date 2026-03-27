"""
End-to-end SEC filing pipeline and Markdown merge utilities.
"""

from __future__ import annotations

import shutil
import tempfile
import time
from pathlib import Path
from typing import Dict, Iterable, List, Optional

from document_converters import convert_local_file_to_markdown, save_markdown
from sec_edgar_client import FilingRecord, SECClient
from sec_form_map import build_markdown_filename, sanitize_for_path


def build_filing_markdown_header(record: FilingRecord, processing_status: str) -> str:
    lines = [
        "# Filing Information",
        "",
        f"- Original Filename: {record.primary_document}",
        f"- Form Type: {record.form_type}",
        f"- Filing Date: {record.filing_date}",
        f"- Accession Number: {record.accession_number}",
        f"- Original File Extension: {record.extension}",
    ]
    if record.document_description:
        lines.append(f"- Document Description: {record.document_description}")
    lines.append(f"- Processing Status: {processing_status}")
    lines.append("")
    return "\n".join(lines)


def convert_recent_filings_to_markdown(
    cik: str,
    user_agent: str,
    output_dir: Path,
    limit: Optional[int] = None,
    sleep_seconds: float = 0.5,
) -> List[Dict]:
    """
    Download recent filings from SEC and convert them to Markdown.
    """
    client = SECClient(cik=cik, user_agent=user_agent)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    temp_dir = Path(tempfile.mkdtemp(prefix="sec_edgar_"))
    results: List[Dict] = []

    try:
        for record in client.get_recent_filings(limit=limit):
            result = {
                "form_type": record.form_type,
                "primary_document": record.primary_document,
                "filing_date": record.filing_date,
                "accession_number": record.accession_number,
                "status": "started",
                "saved_path": None,
            }

            try:
                local_filename = f"{record.accession_number}{record.extension or '.dat'}"
                local_path = temp_dir / local_filename
                client.download_document(record.accession_number, record.primary_document, local_path)

                markdown_body = convert_local_file_to_markdown(local_path)
                header = build_filing_markdown_header(record, "converted to Markdown")
                full_markdown = f"{header}\n{markdown_body}".strip() + "\n"

                form_dir = output_dir / sanitize_for_path(record.form_type)
                md_name = build_markdown_filename(record.form_type, record.filing_date, record.accession_number)
                saved_path = save_markdown(full_markdown, form_dir / md_name)

                result["status"] = "success"
                result["saved_path"] = str(saved_path)
            except Exception as exc:
                result["status"] = f"error: {exc}"

            results.append(result)
            time.sleep(sleep_seconds)
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)

    return results


def convert_html_folder_to_markdown(input_dir: Path, output_dir: Optional[Path] = None) -> List[Path]:
    """
    Convert every HTML-like file in a folder to Markdown.
    """
    input_dir = Path(input_dir)
    output_dir = Path(output_dir) if output_dir else input_dir / "MD"
    output_dir.mkdir(parents=True, exist_ok=True)

    converted: List[Path] = []
    for path in sorted(input_dir.iterdir()):
        if path.suffix.lower() not in {".htm", ".html", ".xml"}:
            continue
        markdown_text = convert_local_file_to_markdown(path)
        output_path = output_dir / f"{path.stem}.md"
        save_markdown(markdown_text, output_path)
        converted.append(output_path)

    return converted


def merge_markdown_files(input_dir: Path, output_file: Path, recursive: bool = False) -> Path:
    """
    Merge Markdown files into one file.
    """
    input_dir = Path(input_dir)
    output_file = Path(output_file)
    output_file.parent.mkdir(parents=True, exist_ok=True)

    pattern = "**/*.md" if recursive else "*.md"
    files = sorted(path for path in input_dir.glob(pattern) if path.is_file())

    parts: List[str] = []
    for path in files:
        relative = path.relative_to(input_dir)
        parts.append(f"# {relative.as_posix()}\n")
        parts.append(path.read_text(encoding="utf-8", errors="ignore"))
        parts.append("\n\n---\n")

    output_file.write_text("\n".join(parts), encoding="utf-8")
    return output_file
