"""
SEC EDGAR API helpers for listing filings and downloading primary documents.
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable, List, Optional

import pandas as pd
import requests

from sec_form_map import sanitize_for_path


@dataclass
class FilingRecord:
    form_type: str
    primary_document: str
    filing_date: str
    accession_number: str
    document_description: str = ""

    @property
    def extension(self) -> str:
        return Path(self.primary_document).suffix.lower()

    def to_dict(self) -> dict:
        return asdict(self)


class SECClient:
    """
    Lightweight client for the public SEC submissions endpoint.
    """

    def __init__(self, cik: str, user_agent: str, timeout: int = 30) -> None:
        self.cik = str(cik).zfill(10)
        self.user_agent = user_agent
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": user_agent})

    @property
    def submissions_url(self) -> str:
        return f"https://data.sec.gov/submissions/CIK{self.cik}.json"

    def get_recent_filings(self, limit: Optional[int] = None) -> List[FilingRecord]:
        response = self.session.get(self.submissions_url, timeout=self.timeout)
        response.raise_for_status()
        data = response.json()
        recent = data.get("filings", {}).get("recent", {})
        accessions = recent.get("accessionNumber", [])
        forms = recent.get("form", [])
        docs = recent.get("primaryDocument", [])
        dates = recent.get("filingDate", [])
        descriptions = recent.get("primaryDocDescription", [])

        records: List[FilingRecord] = []
        for accession, form, doc, date, description in zip(accessions, forms, docs, dates, descriptions):
            records.append(
                FilingRecord(
                    form_type=form,
                    primary_document=doc,
                    filing_date=date,
                    accession_number=accession,
                    document_description=description or "",
                )
            )

        if limit is not None:
            records = records[:limit]
        return records

    def get_recent_filings_frame(self, limit: Optional[int] = None) -> pd.DataFrame:
        records = [record.to_dict() for record in self.get_recent_filings(limit=limit)]
        frame = pd.DataFrame(records)
        if not frame.empty:
            frame["file_extension"] = frame["primary_document"].map(lambda x: Path(x).suffix.lower())
        return frame

    def build_document_url(self, accession_number: str, primary_document: str) -> str:
        accession_no_dash = accession_number.replace("-", "")
        cik_no_leading_zeros = str(int(self.cik))
        return (
            f"https://www.sec.gov/Archives/edgar/data/"
            f"{cik_no_leading_zeros}/{accession_no_dash}/{primary_document}"
        )

    def download_document(
        self,
        accession_number: str,
        primary_document: str,
        output_path: Path,
    ) -> Path:
        url = self.build_document_url(accession_number, primary_document)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        response = self.session.get(url, timeout=self.timeout)
        response.raise_for_status()
        output_path.write_bytes(response.content)
        return output_path

    def download_recent_primary_documents(
        self,
        output_dir: Path,
        limit: Optional[int] = None,
        sleep_seconds: float = 0.5,
    ) -> List[Path]:
        import time

        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        saved_files: List[Path] = []

        for record in self.get_recent_filings(limit=limit):
            suffix = Path(record.primary_document).suffix or ".dat"
            description_part = sanitize_for_path(record.document_description or "document")
            filename = (
                f"{sanitize_for_path(record.form_type)}_"
                f"{record.filing_date}_"
                f"{description_part}_"
                f"{record.accession_number}{suffix}"
            )
            output_path = output_dir / filename
            if not output_path.exists():
                self.download_document(record.accession_number, record.primary_document, output_path)
            saved_files.append(output_path)
            time.sleep(sleep_seconds)

        return saved_files
