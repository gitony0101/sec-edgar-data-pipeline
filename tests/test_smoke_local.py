from pathlib import Path

from sec_edgar_pipeline.converters import html_to_markdown
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


def test_client_build_url_smoke():
    client = SECClient(cik="320193", user_agent="Unit Test (unit@test.example)")
    url = client.build_document_url("0000320193-24-000123", "a10k.htm")
    assert "320193/000032019324000123/a10k.htm" in url
