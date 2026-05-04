# FILE REVIEW NOTE

## FILE_PATH
sec_edgar_pipeline/pipeline.py

## ROLE
core_pipeline_module

## REVIEW_STATUS
reviewed

## FACTS
### sec_edgar_pipeline/pipeline.py

- path: sec_edgar_pipeline/pipeline.py
- line_count: 120
- imports:
  - __future__.annotations
  - shutil
  - tempfile
  - time
  - pathlib.Path
  - typing.Dict
  - typing.List
  - typing.Optional
  - converters.convert_local_file_to_markdown
  - converters.save_markdown
  - form_map.build_markdown_filename
  - form_map.sanitize_for_path
  - sec_client.FilingRecord
  - sec_client.SECClient
- functions:
  - build_filing_markdown_header
  - convert_recent_filings_to_markdown
  - convert_html_folder_to_markdown
  - merge_markdown_files
- classes:
  - none

## CURRENT_OBSERVATIONS
- The file is named `pipeline.py` and is located in `sec_edgar_pipeline/`.
- The file has 120 lines.
- The file imports modules related to file operations (`shutil`, `tempfile`, `time`, `pathlib.Path`), typing, and specific modules for working with SEC filings (`sec_client.FilingRecord`, `sec_client.SECClient`).
- The file defines several functions: `build_filing_markdown_header`, `convert_recent_filings_to_markdown`, `convert_html_folder_to_markdown`, and `merge_markdown_files`.
- In `_process_single_record`, the output subdirectory is built with `sanitize_for_path(record.form_type)`.
- The Markdown filename comes from `build_markdown_filename(record.form_type, record.filing_date, record.accession_number)` and is passed directly to `save_markdown(...)`.
- There is no second-pass validation or sanitization of the returned filename inside `pipeline.py`.

## POSSIBLE_OVERLAP
- Naming responsibility overlaps with `form_map.py`, but `pipeline.py` is the caller that decides whether any downstream guard exists after filename construction.

## POSSIBLE_CLEANUP
- `pipeline.py` currently relies on `form_map.py` as the effective Markdown filename safety boundary.
- `record.filing_date` is forwarded into the naming chain without local validation.
- Very long output filenames remain possible because `pipeline.py` does not enforce a length boundary after filename generation.

## NEEDS_CROSS_CHECK_WITH
- sec_client.FilingRecord
- sec_client.SECClient
- converters.convert_local_file_to_markdown
- converters.save_markdown
- form_map.build_markdown_filename
- form_map.sanitize_for_path

## NEXT_ACTION
- Keep `form_map.py` cross-check findings attached to this file when discussing future naming-hardening work.
- Verify whether downstream save behavior should remain trust-based or add a final path-validation layer in a later product-code round.

## REVIEW_DECISION
reviewed
