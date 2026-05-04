"""XML-specific parsers for SEC ownership filings."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List

import xmltodict

from .converters import html_to_markdown


def xml_file_to_markdown(file_path: Path) -> str:
    """Convert an XML filing to Markdown by treating it as markup content."""
    xml_text = Path(file_path).read_text(encoding="utf-8", errors="ignore")
    return html_to_markdown(xml_text)


def parse_form4_xml_to_json(file_path: Path) -> Dict[str, Any]:
    """Extract a compact JSON structure from a Form 4 ownership XML file."""
    xml_text = Path(file_path).read_text(encoding="utf-8", errors="ignore")
    xml_dict = xmltodict.parse(xml_text)

    root_key = next(iter(xml_dict.keys()))
    if root_key == "xmlData":
        ownership_doc = xml_dict.get("xmlData", {}).get("ownershipDocument", {})
    else:
        ownership_doc = xml_dict.get("ownershipDocument", {})

    reporting_owner = (ownership_doc.get("reportingOwner") or {})
    issuer = (ownership_doc.get("issuer") or {})

    transactions = (ownership_doc.get("nonDerivativeTable") or {}).get("nonDerivativeTransaction", [])
    if isinstance(transactions, dict):
        transactions = [transactions]

    non_derivative: List[Dict[str, Any]] = []
    for tx in transactions:
        non_derivative.append(
            {
                "transactionDate": tx.get("transactionDate", {}).get("value"),
                "transactionCode": tx.get("transactionCoding", {}).get("transactionCode"),
                "securityTitle": tx.get("securityTitle", {}).get("value"),
                "transactionShares": tx.get("transactionAmounts", {}).get("transactionShares", {}).get("value"),
                "transactionPricePerShare": tx.get("transactionAmounts", {}).get("transactionPricePerShare", {}).get("value"),
                "transactionAcquiredDisposedCode": tx.get("transactionAmounts", {}).get("transactionAcquiredDisposedCode", {}).get("value"),
                "sharesOwnedFollowingTransaction": tx.get("postTransactionAmounts", {}).get("sharesOwnedFollowingTransaction", {}).get("value"),
                "ownershipNature": tx.get("ownershipNature", {}).get("directOrIndirectOwnership", {}).get("value"),
            }
        )

    return {
        "reportingOwner": {
            "rptOwnerCik": reporting_owner.get("reportingOwnerId", {}).get("rptOwnerCik"),
            "rptOwnerName": reporting_owner.get("reportingOwnerId", {}).get("rptOwnerName"),
        },
        "issuer": {
            "issuerCik": issuer.get("issuerCik"),
            "issuerName": issuer.get("issuerName"),
            "issuerTradingSymbol": issuer.get("issuerTradingSymbol"),
        },
        "nonDerivativeTransactions": non_derivative,
        "originalFilename": Path(file_path).name,
        "formType": "4",
    }


def save_json(data: Dict[str, Any], output_path: Path) -> Path:
    """Save JSON data with UTF-8 encoding."""
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return output_path
