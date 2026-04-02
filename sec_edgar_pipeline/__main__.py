"""CLI entry points for SEC EDGAR pipeline."""

from __future__ import annotations

import argparse
from pathlib import Path

from .config import settings_from_env
from .pipeline import convert_recent_filings_to_markdown


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Download recent SEC filings and convert them to Markdown")
    parser.add_argument("--cik", default=None, help="CIK value. Falls back to SEC_CIK env var.")
    parser.add_argument("--user-agent", default=None, help="SEC User-Agent with contact info. Falls back to SEC_USER_AGENT.")
    parser.add_argument("--output-dir", default=None, help="Output directory. Falls back to SEC_OUTPUT_DIR.")
    parser.add_argument("--limit", type=int, default=None, help="Number of recent filings to process.")
    parser.add_argument("--sleep-seconds", type=float, default=None, help="Delay between requests.")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    env_settings = settings_from_env()
    cik = args.cik or env_settings.cik
    user_agent = args.user_agent or env_settings.user_agent
    output_dir = Path(args.output_dir) if args.output_dir else env_settings.output_dir
    limit = args.limit if args.limit is not None else env_settings.limit
    sleep_seconds = args.sleep_seconds if args.sleep_seconds is not None else env_settings.sleep_seconds

    if not cik or not user_agent:
        parser.error("Both CIK and user agent are required (via CLI args or environment variables).")

    results = convert_recent_filings_to_markdown(
        cik=cik,
        user_agent=user_agent,
        output_dir=output_dir,
        limit=limit,
        sleep_seconds=sleep_seconds,
    )
    success = sum(1 for item in results if item["status"] == "success")
    print(f"Processed {len(results)} filings, successful: {success}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
