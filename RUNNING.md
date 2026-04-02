# RUNNING

## Audit summary (main issues found)

1. **Mixed responsibilities**: SEC fetch logic, conversion logic, and Google Drive operations were all in `scripts/` with notebook-style coupling.
2. **Import fragility**: modules imported siblings without package-relative imports, which breaks in normal package usage.
3. **Colab assumptions in core flow**: direct `google.colab` auth attempts inside runtime logic.
4. **Configuration hardening needed**: no clean CLI/env-driven execution path for CIK/user-agent/output.
5. **Repository presentation gaps**: README described files that do not exist and did not reflect runnable entry points.

## What now works locally/cloud

- Package imports from `sec_edgar_pipeline`.
- CLI execution with env vars or CLI flags.
- Local smoke tests for converter/form-map/XML parser/client URL path.
- Optional SEC network smoke test (`RUN_NETWORK_TESTS=1`) using public CIK.

## What still depends on credentials or external tools

- Google Drive operations require Google API credentials and optional deps.
- DOCX conversion needs `pypandoc` plus a working pandoc installation.
- Live SEC smoke tests require outbound internet and a valid SEC `User-Agent` string with contact info.

## How to run

### 1) Install

```bash
pip install -r requirements.txt
```

### 2) Run local smoke tests (no network)

```bash
pytest -q tests/test_smoke_local.py
```

### 3) Run optional SEC network smoke test

```bash
export RUN_NETWORK_TESTS=1
export SEC_USER_AGENT="Your Name (you@example.com)"
pytest -q tests/test_smoke_sec_network.py
```

### 4) Run the pipeline

```bash
export SEC_CIK=320193
export SEC_USER_AGENT="Your Name (you@example.com)"
python -m sec_edgar_pipeline --limit 2 --output-dir outputs/filings_markdown
```

### 5) Minimal end-to-end single command

```bash
SEC_CIK=320193 SEC_USER_AGENT="Your Name (you@example.com)" python -m sec_edgar_pipeline --limit 1 --output-dir outputs/filings_markdown
```
