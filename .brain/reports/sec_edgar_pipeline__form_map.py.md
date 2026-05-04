# Analysis Report

- target: sec_edgar_pipeline/form_map.py
- action: 2
- role: 7
- role_label: form_mapping_utility_module

## Deterministic Draft

DRAFT: This file appears to provide SEC form mapping and filename/path helper utilities.
DRAFT: Extra code context was fetched because the file is moderately sized.

## First 80 Lines

```python
"""Shared constants and filename helpers for SEC filing processing."""

from __future__ import annotations

import re
from typing import Dict

FORM_TYPE_MAP: Dict[str, str] = {
    "8-K": "Current_Events_Report",
    "8-K/A": "Current_Events_Amendment",
    "8-K12B": "Section_12B_8K_Report",
    "8-A12B": "Section_12B_8A_Report",
    "10-Q": "Quarterly_Financial_Report",
    "10-K": "Annual_Financial_Report",
    "10-K/A": "Annual_Report_Amendment",
    "3": "Initial_Insider_Report",
    "4": "Insider_Trading_Report",
    "4/A": "Insider_Trading_Amendment",
    "5": "Annual_Insider_Report",
    "S-1": "IPO_Registration",
    "S-1/A": "IPO_Registration_Amendment",
    "S-1MEF": "Multi_Offering_Registration",
    "S-3": "Simplified_Registration",
    "S-8": "Employee_Stock_Registration",
    "424B3": "Prospectus_Filing",
    "424B4": "Prospectus_Filing",
    "424B5": "Prospectus_Filing",
    "SC 13D": "Active_Investor_Report",
    "SC 13D/A": "13D_Amendment_Report",
    "SCHEDULE 13D/A": "13D_Amendment_Report",
    "SC 13G": "Passive_Investor_Report",
    "SC 13G/A": "13G_Amendment_Report",
    "SC 13E3": "Privatization_Report",
    "SC 13E3/A": "Privatization_Amendment_Report",
    "DEF 14A": "Final_Proxy_Statement",
    "DEFM14A": "Final_Proxy_Statement",
    "DEFA14A": "Additional_Proxy_Statement",
    "DEFR14A": "Final_Revised_Proxy",
    "PRE 14A": "Preliminary_Proxy_Statement",
    "PRER14A": "Preliminary_Proxy_Statement",
    "PREM14A": "Preliminary_Merger_Proxy",
    "25-NSE": "Delisting_Notice",
    "D": "Private_Offering_Notice",
    "EFFECT": "Registration_Effective_Notice",
    "FWP": "Free_Writing_Prospectus",
    "POS AM": "Post_Effective_Amendment",
    "ARS": "Annual_Report",
    "ARS/A": "Annual_Report_Amendment",
    "CORRESP": "SEC_Correspondence",
    "CERT": "Listing_Certification",
    "SEC STAFF LETTER": "SEC_Staff_Letter",
    "UPLOAD": "General_Upload_File",
    "DRS": "Direct_Registration_Statement",
    "DRS/A": "Direct_Registration_Amendment",
    "DRSLTR": "Direct_Registration_Letter",
}


def sanitize_for_path(value: str) -> str:
    """Make a string safe for folder names and filenames."""
    safe = value.strip()
    safe = safe.replace("/", "_").replace("\\", "_")
    safe = re.sub(r"\s+", "_", safe)
    safe = re.sub(r"[^A-Za-z0-9._-]", "", safe)
    return safe or "unknown"


def get_concise_name(form_type: str) -> str:
    """Return a concise English label for an SEC form type."""
    return sanitize_for_path(FORM_TYPE_MAP.get(form_type, form_type))


def build_markdown_filename(
    form_type: str,
    filing_date: str,
    accession_number: str,
    extension: str = ".md",
) -> str:
    """Build a normalized output filename."""
    concise = get_concise_name(form_type)
```

