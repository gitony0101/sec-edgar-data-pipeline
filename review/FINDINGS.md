# Project Review Findings

## Reviewed Single Files
- sec_edgar_pipeline/__main__.py : **reviewed**
- sec_edgar_pipeline/config.py : **reviewed**
- sec_edgar_pipeline/converters.py : **reviewed**
- sec_edgar_pipeline/form_map.py : **reviewed**
- sec_edgar_pipeline/pipeline.py : **reviewed**
- sec_edgar_pipeline/sec_client.py : **reviewed**
- sec_edgar_pipeline/xml_parsers.py : **reviewed**

## Reviewed Cross-Checks
- sec_edgar_pipeline/form_map.py vs sec_edgar_pipeline/pipeline.py : **reviewed**
- sec_edgar_pipeline/form_map.py vs sec_edgar_pipeline/sec_client.py : **reviewed**

## Overlap & Redundancy Candidates
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/pipeline.py: - Observed: `pipeline.py` still trusts `record.filing_date`, but `build_markdown_filename(...)` now sanitizes that field before constructing the final filename.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/pipeline.py: - Observed: `pipeline.py` treats `form_map.py` as the naming boundary for the Markdown filename and only separately sanitizes the output subdirectory from `record.form_type`.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/pipeline.py: - Observed: there is no second-pass filename sanitization in `pipeline.py` after `build_markdown_filename(...)` returns.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/pipeline.py: - Observed: unknown form types now produce the explicit filename prefix `Unknown_Form`.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/pipeline.py: - Possible: auditability is still limited because the filename fallback is explicit, but no separate audit event is recorded when that fallback path is used.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/pipeline.py: - Possible: malformed filing dates can still be semantically wrong even though the current implementation now sanitizes them for filename safety.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/pipeline.py: - Possible: very long filenames remain possible because the combined filename includes concise form label, raw form type, raw filing date, and accession number.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/sec_client.py: - Observed: `sec_client.py` already uses `sanitize_for_path` in its own local download naming flow, which makes `form_map.py` and `sec_client.py` share responsibility for path-safe naming behavior.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/sec_client.py: - Observed: `sec_client.py` does not validate the format of `filing_date` before storing it in `FilingRecord`.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/sec_client.py: - Observed: `sec_client.py` is the upstream source of `filing_date` for the naming chain.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/sec_client.py: - Observed: unknown form types now surface as `Unknown_Form` in the Markdown filename path.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/sec_client.py: - Possible: abnormal SEC metadata would enter both naming chains because `record.filing_date` is trusted in both `download_recent_primary_documents()` and downstream Markdown filename generation.
- sec_edgar_pipeline/form_map.py / sec_edgar_pipeline/sec_client.py: - Possible: auditability is still limited because no explicit marker is recorded at metadata-ingestion time when a raw unmapped form passes through.
- sec_edgar_pipeline/form_map.py: - Filename construction overlap exists conceptually with other output-path decisions in `sec_edgar_pipeline/pipeline.py`, but this module is the clear normalization boundary.
- sec_edgar_pipeline/form_map.py: - Sanitization semantics are also reused directly by `sec_client.py`, so responsibility is shared between metadata ingestion and helper-level normalization rather than isolated to one module.
- sec_edgar_pipeline/pipeline.py: - Naming responsibility overlaps with `form_map.py`, but `pipeline.py` is the caller that decides whether any downstream guard exists after filename construction.
- sec_edgar_pipeline/sec_client.py: - Naming responsibility overlaps with `form_map.py` because `sec_client.py` both ingests upstream metadata and reuses shared sanitization helpers in its own local download path.
- sec_edgar_pipeline/sec_client.py: - The functions related to fetching and downloading filings might overlap with other data retrieval or document processing logic if they are called from a different module.

## Cleanup Candidates
- sec_edgar_pipeline/form_map.py: - The combination of concise label and raw form type may still allow very long filenames for unusual inputs, especially when accession numbers or form aliases are verbose.
- sec_edgar_pipeline/form_map.py: - Unknown form types now produce an explicit `Unknown_Form` prefix, but the project still does not record an audit event when that fallback path is used.
- sec_edgar_pipeline/form_map.py: - `filing_date` is now sanitized for filename safety, but the function still does not validate whether the date has the expected semantic format.
- sec_edgar_pipeline/pipeline.py: - Very long output filenames remain possible because `pipeline.py` does not enforce a length boundary after filename generation.
- sec_edgar_pipeline/pipeline.py: - `pipeline.py` currently relies on `form_map.py` as the effective Markdown filename safety boundary.
- sec_edgar_pipeline/pipeline.py: - `record.filing_date` is forwarded into the naming chain without local validation.
- sec_edgar_pipeline/sec_client.py: - Check if the use of `form_map.sanitize_for_path` is appropriate and if it handles all possible path inputs correctly.
- sec_edgar_pipeline/sec_client.py: - Ensure error handling is robust in network requests and file operations.
- sec_edgar_pipeline/sec_client.py: - Review docstrings and type hints for clarity and correctness.
- sec_edgar_pipeline/sec_client.py: - Unknown or unusual form metadata remains operationally accepted, but there is no explicit audit marker when fallback sanitization is used.
- sec_edgar_pipeline/sec_client.py: - `filing_date` is trusted from upstream SEC metadata and reused in local filenames without explicit format checks.
