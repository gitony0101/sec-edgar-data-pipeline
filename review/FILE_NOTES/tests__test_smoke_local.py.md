# FILE REVIEW NOTE

## FILE_PATH
tests/test_smoke_local.py

## ROLE
validation_surface_smoke_test_module

## REVIEW_STATUS
reviewed

## FACTS
### tests/test_smoke_local.py

- path: tests/test_smoke_local.py
- imports:
  - pathlib.Path
  - sec_edgar_pipeline.converters.html_to_markdown
  - sec_edgar_pipeline.form_map.build_markdown_filename
  - sec_edgar_pipeline.form_map.sanitize_for_path
  - sec_edgar_pipeline.sec_client.SECClient
  - sec_edgar_pipeline.xml_parsers.parse_form4_xml_to_json
- test functions:
  - test_html_to_markdown_smoke
  - test_form_filename_smoke
- test_form_filename_unknown_form_smoke
- test_form_filename_malformed_date_smoke
- test_parse_form4_xml_smoke
- test_parse_form4_xml_wrapped_root_smoke
- test_client_build_url_smoke
- test_settings_from_env_invalid_limit_smoke
- test_settings_from_env_invalid_sleep_seconds_smoke

## CURRENT_OBSERVATIONS
- This file is the current minimum runnable validation surface for the local patch-trial workflow.
- It directly anchors `form_map.py` behavior for known-form output, unknown-form fallback, and malformed-date filename sanitization.
- It also anchors malformed `SEC_LIMIT` parsing behavior in `config.py`.
- It also anchors malformed `SEC_SLEEP_SECONDS` parsing behavior in `config.py`.
- It provides lightweight smoke coverage for converter HTML rendering, Form 4 XML parsing in direct-root and wrapped-root forms, and SEC document URL construction.
- The file validates isolated helper behavior, not end-to-end orchestration.

## POSSIBLE_OVERLAP
- Validation responsibility overlaps with the formal review state because patch-trial decisions now depend on this file to convert prose findings into executable evidence.

## POSSIBLE_CLEANUP
- The file does not yet cover very long filename behavior in `build_markdown_filename()`.
- The file does not exercise any audit-event behavior for unknown-form fallback, because the current implementation exposes only filename output.
- The file does not validate `pipeline.py` orchestration paths, so it should not be used to justify changes there.

## NEEDS_CROSS_CHECK_WITH
- sec_edgar_pipeline/form_map.py
- sec_edgar_pipeline/config.py
- sec_edgar_pipeline/converters.py
- sec_edgar_pipeline/xml_parsers.py
- sec_edgar_pipeline/sec_client.py

## NEXT_ACTION
- Use this file as the minimum executable evidence surface when deciding whether later helper-boundary moves in `form_map.py`, `config.py`, or `xml_parsers.py` are mature enough for execution.

## REVIEW_DECISION
reviewed
