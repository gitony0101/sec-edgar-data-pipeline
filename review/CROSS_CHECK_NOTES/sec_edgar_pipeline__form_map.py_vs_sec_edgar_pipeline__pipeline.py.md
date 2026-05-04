# CROSS CHECK NOTE

## STATUS
reviewed

## FILE_A
sec_edgar_pipeline/form_map.py

## FILE_B
sec_edgar_pipeline/pipeline.py

## FILE_A_ROLE
form_mapping_utility_module

## FILE_B_ROLE
core_pipeline_module

## FILE_A_OBSERVATIONS
- `sanitize_for_path` normalizes strings for folder names and filename fragments by replacing slashes and whitespace, removing non `[A-Za-z0-9._-]` characters, and falling back to `unknown`.
- `build_markdown_filename` now sanitizes `form_type`, `filing_date`, and `accession_number` before returning the filename.
- Unknown form types now use the stable filename prefix `Unknown_Form` while preserving the sanitized raw form type fragment.

## FILE_B_OBSERVATIONS
- `_process_single_record` builds `form_dir` as `output_dir / sanitize_for_path(record.form_type)`.
- `_process_single_record` then calls `build_markdown_filename(record.form_type, record.filing_date, record.accession_number)` and passes the returned name directly to `save_markdown(...)`.
- `pipeline.py` uses `record.filing_date` only as received on `FilingRecord`; it does not validate or re-sanitize that field before filename generation.

## POSSIBLE_SHARED_CONCERNS
- Observed: `pipeline.py` treats `form_map.py` as the naming boundary for the Markdown filename and only separately sanitizes the output subdirectory from `record.form_type`.
- Observed: `pipeline.py` still trusts `record.filing_date`, but `build_markdown_filename(...)` now sanitizes that field before constructing the final filename.
- Observed: there is no second-pass filename sanitization in `pipeline.py` after `build_markdown_filename(...)` returns.
- Observed: unknown form types now produce the explicit filename prefix `Unknown_Form`.
- Possible: malformed filing dates can still be semantically wrong even though the current implementation now sanitizes them for filename safety.
- Possible: very long filenames remain possible because the combined filename includes concise form label, raw form type, raw filing date, and accession number.
- Possible: auditability is still limited because the filename fallback is explicit, but no separate audit event is recorded when that fallback path is used.

## DIFFERENCE_CHECKPOINTS
- Observed: `form_map.py` owns normalization helpers and deterministic filename composition.
- Observed: `pipeline.py` owns when and where those helpers are applied during Markdown output generation.
- Observed: directory safety for Markdown output is split: `pipeline.py` sanitizes `record.form_type` for the folder, while `form_map.py` sanitizes form type and accession number inside the filename.
- Observed: `pipeline.py` does not currently add an independent guard after `form_map.py`; it relies on `form_map.py` as the effective filename safety boundary for Markdown outputs.

## NEXT_ACTION
- Record in file notes that `filing_date` currently crosses the naming boundary without explicit validation.
- Treat `form_map.py` as the effective Markdown filename safety boundary until product code changes are explicitly requested.

## SOURCE_REASON
Grounded manual cross-check of naming and path-safety boundary between filename helpers and Markdown output orchestration.
