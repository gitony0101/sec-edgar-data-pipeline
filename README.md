# SEC EDGAR Data Pipeline

A small Python pipeline for downloading recent SEC EDGAR filings by CIK, converting primary documents to Markdown, and parsing Form 4 XML.

## 30-second overview

- `sec_edgar_pipeline/sec_client.py`: SEC API client with respectful headers.
- `sec_edgar_pipeline/pipeline.py`: fetch + download + convert recent filings.
- `sec_edgar_pipeline/converters.py`: HTML/XML/PDF/TXT to Markdown.
- `sec_edgar_pipeline/xml_parsers.py`: Form 4 XML to normalized JSON.
- `sec_edgar_pipeline/google_drive.py`: optional Google Drive integration isolated from core.
- `tests/`: local smoke tests + optional network smoke test.

## Quick start

```bash
python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
```

Output defaults to `outputs/filings_markdown` unless `SEC_OUTPUT_DIR` or `--output-dir` is set.

## Minimal end-to-end command

```bash
SEC_CIK=320193 SEC_USER_AGENT="Your Name (you@example.com)" python -m sec_edgar_pipeline --limit 2 --output-dir outputs/filings_markdown
```

## Notes

- Core pipeline has no Google Colab dependency.
- Google Drive support is optional and imported lazily.

See `RUNNING.md` for full run and validation details.
