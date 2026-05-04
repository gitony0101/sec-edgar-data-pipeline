# FILE REVIEW NOTE

## FILE_PATH
sec_edgar_pipeline/converters.py

## ROLE
conversion_utility_module

## REVIEW_STATUS
reviewed

## FACTS
### sec_edgar_pipeline/converters.py

- path: sec_edgar_pipeline/converters.py
- line_count: 70
- imports:
  - __future__.annotations
  - subprocess
  - pathlib.Path
  - typing.Optional
  - markdownify
  - pypdf.PdfReader
  - pypandoc
- functions:
  - html_to_markdown
  - html_file_to_markdown
  - pdf_to_markdown
  - txt_to_markdown
  - convert_local_file_to_markdown
  - save_markdown
  - markdown_to_docx
  - try_ocr_pdf
- classes:
  - none

## CURRENT_OBSERVATIONS
- `html_to_markdown` is a foundational helper because both direct HTML conversion and XML-to-Markdown conversion depend on it.
- `convert_local_file_to_markdown` is the file-type dispatch boundary for local conversions.
- `markdown_to_docx` and `try_ocr_pdf` introduce optional external-tool dependence (`pypandoc`, `ocrmypdf`) that sits outside the current smoke-test surface.
- The current smoke surface touches only HTML conversion directly; PDF, OCR, and DOCX helper paths remain unanchored.

## POSSIBLE_OVERLAP
- Overlap exists with `xml_parsers.py` because XML content is routed through this module’s HTML conversion path for Markdown rendering.

## POSSIBLE_CLEANUP
- External tool paths remain under-validated and should not become execution candidates without explicit validation expansion.
- `convert_local_file_to_markdown` is a concentrated helper boundary, but its non-HTML branches currently lack direct smoke coverage.

## NEEDS_CROSS_CHECK_WITH
- sec_edgar_pipeline/xml_parsers.py
- tests/test_smoke_local.py

## NEXT_ACTION
- Keep future execution suggestions here focused on helper-boundary validation expansion rather than converter-chain refactoring.

## REVIEW_DECISION
reviewed
