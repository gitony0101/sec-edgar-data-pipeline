"""
XML-specific parsers for SEC ownership filings.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List

import xmltodict

from document_converters import html_to_markdown


def xml_file_to_markdown(file_path: Path) -> str:
    """
    Convert an XML filing to Markdown by treating it as markup content.
    """
    xml_text = Path(file_path).read_text(encoding="utf-8", errors="ignore")
    return html_to_markdown(xml_text)


def parse_form4_xml_to_json(file_path: Path) -> Dict[str, Any]:
    """
    Extract a compact JSON structure from a Form 4 ownership XML file.
    """
    xml_text = Path(file_path).read_text(encoding="utf-8", errors="ignore")
    xml_dict = xmltodict.parse(xml_text)

    root_key = next(iter(xml_dict.keys()))
    if root_key == "xmlData":
        ownership_doc = xml_dict.get("xmlData", {}).get("ownershipDocument", {})
    elif root_key == "ownershipDocument":
        ownership_doc = xml_dict.get("ownershipDocument", {})
    else:
        ownership_doc = xml_dict.get("ownershipDocument", {})

    reporting_owner = ownership_doc.get("reportingOwner", {})
    issuer = ownership_doc.get("issuer", {})
    non_derivative: List[Dict[str, Any]] = []

    nd_table = ownership_doc.get("nonDerivativeTable", {})
    transactions = nd_table.get("nonDerivativeTransaction", [])
    if isinstance(transactions, dict):
        transactions = [transactions]

    for transaction in transactions:
        non_derivative.append(
            {
                "transactionDate": transaction.get("transactionDate", {}).get("value"),
                "transactionCode": transaction.get("transactionCoding", {}).get("transactionCode"),
                "securityTitle": transaction.get("securityTitle", {}).get("value"),
                "transactionShares": transaction.get("transactionAmounts", {}).get("transactionShares", {}).get("value"),
                "transactionPricePerShare": transaction.get("transactionAmounts", {}).get("transactionPricePerShare", {}).get("value"),
                "transactionAcquiredDisposedCode": transaction.get("transactionAmounts", {}).get("transactionAcquiredDisposedCode", {}).get("value"),
                "sharesOwnedFollowingTransaction": transaction.get("postTransactionAmounts", {}).get("sharesOwnedFollowingTransaction", {}).get("value"),
                "ownershipNature": transaction.get("ownershipNature", {}).get("directOrIndirectOwnership", {}).get("value"),
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
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return output_path
