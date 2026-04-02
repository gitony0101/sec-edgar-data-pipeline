import os

import pytest
import requests

from sec_edgar_pipeline.sec_client import SECClient


@pytest.mark.skipif(os.getenv("RUN_NETWORK_TESTS") != "1", reason="Set RUN_NETWORK_TESTS=1 to enable SEC network smoke test")
def test_sec_recent_filings_network_smoke():
    client = SECClient(cik="320193", user_agent=os.getenv("SEC_USER_AGENT", "Smoke Test (smoke@test.example)"))
    try:
        records = client.get_recent_filings(limit=1)
    except requests.RequestException as exc:
        pytest.skip(f"Network/proxy restriction in runtime environment: {exc}")

    assert len(records) == 1
    assert records[0].accession_number
    assert records[0].primary_document
