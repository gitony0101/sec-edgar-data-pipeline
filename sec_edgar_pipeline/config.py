"""Configuration helpers for SEC EDGAR pipeline."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass
class SECSettings:
    cik: str
    user_agent: str
    output_dir: Path
    limit: int | None = None
    sleep_seconds: float = 0.5


DEFAULT_OUTPUT_DIR = Path("outputs/filings_markdown")


def settings_from_env() -> SECSettings:
    """Build settings from environment variables."""
    cik = os.getenv("SEC_CIK", "")
    user_agent = os.getenv("SEC_USER_AGENT", "")
    output_dir = Path(os.getenv("SEC_OUTPUT_DIR", str(DEFAULT_OUTPUT_DIR)))
    limit = os.getenv("SEC_LIMIT")
    sleep_seconds = float(os.getenv("SEC_SLEEP_SECONDS", "0.5"))

    return SECSettings(
        cik=cik,
        user_agent=user_agent,
        output_dir=output_dir,
        limit=int(limit) if limit else None,
        sleep_seconds=sleep_seconds,
    )
