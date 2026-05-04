# CROSS CHECK NOTE

## STATUS
reviewed

## FILE_A
sec_edgar_pipeline/form_map.py

## FILE_B
sec_edgar_pipeline/sec_client.py

## FILE_A_ROLE
form_mapping_utility_module

## FILE_B_ROLE
sec_api_client_module

## FILE_A_OBSERVATIONS
- `sanitize_for_path` is the shared sanitizer used for path-safe folder and filename fragments.
- `build_markdown_filename` now sanitizes `form_type`, `filing_date`, and `accession_number`.
- Unknown form types now use the stable filename prefix `Unknown_Form`, but no separate audit event is emitted.

## FILE_B_OBSERVATIONS
- `get_recent_filings` constructs `FilingRecord(... filing_date=date ...)` directly from the SEC submissions JSON `filings.recent.filingDate` field.
- `download_recent_primary_documents` builds download filenames using `sanitize_for_path(record.form_type)` and `sanitize_for_path(record.document_description or "document")`, but inserts `record.filing_date` raw.
- `primary_document` is not sanitized when used in `build_document_url(...)`; it is part of the remote URL path, not the local filename.

## POSSIBLE_SHARED_CONCERNS
- Observed: `sec_client.py` is the upstream source of `filing_date` for the naming chain.
- Observed: `sec_client.py` does not validate the format of `filing_date` before storing it in `FilingRecord`.
- Observed: `sec_client.py` already uses `sanitize_for_path` in its own local download naming flow, which makes `form_map.py` and `sec_client.py` share responsibility for path-safe naming behavior.
- Possible: abnormal SEC metadata would enter both naming chains because `record.filing_date` is trusted in both `download_recent_primary_documents()` and downstream Markdown filename generation.
- Observed: unknown form types now surface as `Unknown_Form` in the Markdown filename path.
- Possible: auditability is still limited because no explicit marker is recorded at metadata-ingestion time when a raw unmapped form passes through.

## DIFFERENCE_CHECKPOINTS
- Observed: `sec_client.py` owns metadata ingestion from SEC and therefore owns the first boundary where `filing_date`, `form_type`, and `document_description` become local state.
- Observed: `form_map.py` owns the reusable path-sanitization and filename-construction helpers.
- Observed: `sec_client.py` is not the only naming path; it has its own download filename scheme that partially reuses `form_map` sanitization instead of `build_markdown_filename`.
- Possible: responsibility is split rather than singular, with `sec_client.py` owning metadata trust and `form_map.py` owning reusable sanitization semantics.

## NEXT_ACTION
- Keep future review attention on the ingestion boundary for `filing_date` and on the absence of explicit audit markers for unknown form types.
- Use these findings if a later product-code round is opened for validation hardening.

## SOURCE_REASON
Grounded manual cross-check of upstream metadata ingestion versus shared path-sanitization helpers.
