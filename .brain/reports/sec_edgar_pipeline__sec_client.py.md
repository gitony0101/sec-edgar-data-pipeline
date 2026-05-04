# Analysis Report

- target: sec_edgar_pipeline/sec_client.py
- action: 2
- role: 5
- role_label: sec_api_client_module

## Deterministic Draft

DRAFT: This file appears to implement SEC API client helpers and filing download logic.
DRAFT: Extra code context was fetched because the file is non-trivial in size.

## First 80 Lines

```python
"""SEC EDGAR API helpers for listing filings and downloading primary documents."""

from __future__ import annotations

from dataclasses import asdict, dataclass
from pathlib import Path
from typing import List, Optional

import pandas as pd
import requests

from .form_map import sanitize_for_path


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
    """Lightweight client for the public SEC submissions endpoint."""

    def __init__(self, cik: str, user_agent: str, timeout: int = 30) -> None:
        if "@" not in user_agent:
            raise ValueError("SEC user agent should include contact info, e.g. Name (email@example.com)")
        self.cik = str(cik).zfill(10)
        self.user_agent = user_agent
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": user_agent, "Accept-Encoding": "gzip, deflate", "Host": "data.sec.gov"})

    @property
    def submissions_url(self) -> str:
        return f"https://data.sec.gov/submissions/CIK{self.cik}.json"

    def get_recent_filings(self, limit: Optional[int] = None) -> List[FilingRecord]:
        response = self.session.get(self.submissions_url, timeout=self.timeout)
        response.raise_for_status()
        data = response.json()
        recent = data.get("filings", {}).get("recent", {})

        records = [
            FilingRecord(
                form_type=form,
                primary_document=doc,
                filing_date=date,
                accession_number=accession,
                document_description=description or "",
            )
            for accession, form, doc, date, description in zip(
                recent.get("accessionNumber", []),
                recent.get("form", []),
                recent.get("primaryDocument", []),
                recent.get("filingDate", []),
                recent.get("primaryDocDescription", []),
            )
        ]
        return records[:limit] if limit is not None else records

    def get_recent_filings_frame(self, limit: Optional[int] = None) -> pd.DataFrame:
        frame = pd.DataFrame([record.to_dict() for record in self.get_recent_filings(limit=limit)])
        if not frame.empty:
            frame["file_extension"] = frame["primary_document"].map(lambda x: Path(x).suffix.lower())
        return frame

    def build_document_url(self, accession_number: str, primary_document: str) -> str:
        accession_no_dash = accession_number.replace("-", "")
        cik_no_leading_zeros = str(int(self.cik))
        return f"https://www.sec.gov/Archives/edgar/data/{cik_no_leading_zeros}/{accession_no_dash}/{primary_document}"
```

