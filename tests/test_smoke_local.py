from pathlib import Path

import pytest

from sec_edgar_pipeline.converters import html_to_markdown
from sec_edgar_pipeline.config import settings_from_env
from sec_edgar_pipeline.form_map import build_markdown_filename, sanitize_for_path
from sec_edgar_pipeline.sec_client import SECClient
from sec_edgar_pipeline.xml_parsers import parse_form4_xml_to_json


def test_html_to_markdown_smoke():
    markdown = html_to_markdown("<h1>Hello</h1><p>World</p>")
    assert "# Hello" in markdown
    assert "World" in markdown


def test_form_filename_smoke():
    assert sanitize_for_path("10-K/A") == "10-K_A"
    name = build_markdown_filename("10-K", "2025-01-01", "0000000000-25-000001")
    assert name.endswith(".md")
    assert "10-K" in name


def test_form_filename_unknown_form_smoke():
    name = build_markdown_filename("X-??/A", "2025-01-01", "0000000000-25-000001")
    assert name == "Unknown_Form_X-_A_2025-01-01_0000000000-25-000001.md"


def test_form_filename_malformed_date_smoke():
    name = build_markdown_filename("10-K", "2025/01??", "0000000000-25-000001")
    assert name == "Annual_Financial_Report_10-K_2025_01_0000000000-25-000001.md"


def test_parse_form4_xml_smoke(tmp_path: Path):
    xml_path = tmp_path / "form4.xml"
    xml_path.write_text(
        """
<ownershipDocument>
  <reportingOwner><reportingOwnerId><rptOwnerCik>123</rptOwnerCik><rptOwnerName>Owner</rptOwnerName></reportingOwnerId></reportingOwner>
  <issuer><issuerCik>456</issuerCik><issuerName>Issuer</issuerName><issuerTradingSymbol>ABC</issuerTradingSymbol></issuer>
  <nonDerivativeTable>
    <nonDerivativeTransaction>
      <transactionDate><value>2025-01-01</value></transactionDate>
      <transactionCoding><transactionCode>P</transactionCode></transactionCoding>
    </nonDerivativeTransaction>
  </nonDerivativeTable>
</ownershipDocument>
""".strip(),
        encoding="utf-8",
    )
    payload = parse_form4_xml_to_json(xml_path)
    assert payload["issuer"]["issuerName"] == "Issuer"
    assert payload["nonDerivativeTransactions"][0]["transactionCode"] == "P"


def test_parse_form4_xml_wrapped_root_smoke(tmp_path: Path):
    xml_path = tmp_path / "wrapped_form4.xml"
    xml_path.write_text(
        """
<xmlData>
  <ownershipDocument>
    <reportingOwner><reportingOwnerId><rptOwnerCik>123</rptOwnerCik><rptOwnerName>Owner</rptOwnerName></reportingOwnerId></reportingOwner>
    <issuer><issuerCik>456</issuerCik><issuerName>Issuer</issuerName><issuerTradingSymbol>ABC</issuerTradingSymbol></issuer>
    <nonDerivativeTable>
      <nonDerivativeTransaction>
        <transactionDate><value>2025-01-01</value></transactionDate>
        <transactionCoding><transactionCode>P</transactionCode></transactionCoding>
      </nonDerivativeTransaction>
    </nonDerivativeTable>
  </ownershipDocument>
</xmlData>
""".strip(),
        encoding="utf-8",
    )
    payload = parse_form4_xml_to_json(xml_path)
    assert payload["reportingOwner"]["rptOwnerName"] == "Owner"
    assert payload["issuer"]["issuerTradingSymbol"] == "ABC"
    assert payload["nonDerivativeTransactions"][0]["transactionCode"] == "P"


def test_client_build_url_smoke():
    client = SECClient(cik="320193", user_agent="Unit Test (unit@test.example)")
    url = client.build_document_url("0000320193-24-000123", "a10k.htm")
    assert "320193/000032019324000123/a10k.htm" in url


def test_settings_from_env_invalid_limit_smoke(monkeypatch):
    monkeypatch.setenv("SEC_LIMIT", "not-an-int")
    monkeypatch.setenv("SEC_SLEEP_SECONDS", "0.5")
    with pytest.raises(ValueError):
        settings_from_env()


def test_settings_from_env_invalid_sleep_seconds_smoke(monkeypatch):
    monkeypatch.setenv("SEC_LIMIT", "")
    monkeypatch.setenv("SEC_SLEEP_SECONDS", "not-a-float")
    with pytest.raises(ValueError):
        settings_from_env()


def test_parse_form4_xml_empty_table_smoke(tmp_path: Path):
    xml_path = tmp_path / "empty_table.xml"
    xml_path.write_text(
        """
<ownershipDocument>
  <reportingOwner><reportingOwnerId><rptOwnerCik>123</rptOwnerCik><rptOwnerName>Owner</rptOwnerName></reportingOwnerId></reportingOwner>
  <issuer><issuerCik>456</issuerCik><issuerName>Issuer</issuerName><issuerTradingSymbol>ABC</issuerTradingSymbol></issuer>
  <nonDerivativeTable>
  </nonDerivativeTable>
</ownershipDocument>
""".strip(),
        encoding="utf-8",
    )
    payload = parse_form4_xml_to_json(xml_path)
    assert payload["nonDerivativeTransactions"] == []
    assert payload["issuer"]["issuerName"] == "Issuer"
    assert payload["reportingOwner"]["rptOwnerName"] == "Owner"


def test_parse_form4_xml_unknown_root_smoke(tmp_path: Path):
    xml_path = tmp_path / "unknown_root.xml"
    xml_path.write_text(
        """
<someUnknownRoot>
  <reportingOwner><reportingOwnerId><rptOwnerCik>123</rptOwnerCik><rptOwnerName>Owner</rptOwnerName></reportingOwnerId></reportingOwner>
  <issuer><issuerCik>456</issuerCik><issuerName>Issuer</issuerName></issuer>
</someUnknownRoot>
""".strip(),
        encoding="utf-8",
    )
    payload = parse_form4_xml_to_json(xml_path)
    assert payload["nonDerivativeTransactions"] == []
    assert payload["reportingOwner"]["rptOwnerName"] is None
