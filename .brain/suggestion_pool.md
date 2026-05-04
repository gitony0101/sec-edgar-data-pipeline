# SUGGESTION POOL

## CURRENT RANKING
1. next validation-expansion candidate: `sec_edgar_pipeline/xml_parsers.py :: parse_form4_xml_to_json`
2. later validation-expansion candidate: `sec_edgar_pipeline/converters.py :: convert_local_file_to_markdown`
3. closed under current semantics: `sec_edgar_pipeline/config.py :: settings_from_env`
4. blocked broader candidate: `sec_edgar_pipeline/pipeline.py`
5. blocked broader candidate: `sec_edgar_pipeline/sec_client.py`

## WHY THE TOP TWO DIFFER
- `config.py :: settings_from_env` is no longer the next active execution path because the Option A validation loop is complete and no justified bounded Option A patch remains.
- `xml_parsers.py :: parse_form4_xml_to_json` is now the strongest next validation-expansion candidate because it still has an evidence gap that could mature it toward future bounded execution.

## CANDIDATE 001
- source file: `sec_edgar_pipeline/config.py`
- target area: `settings_from_env`
- evidence:
  - malformed `SEC_LIMIT` and `SEC_SLEEP_SECONDS` values currently flow through raw `int()` / `float()` conversion
  - current formal note identifies raw conversion failures as the main user-facing boundary risk
- impact scope: single-file, single-function
- classification: single-file
- current maturity: closed under current Option A semantics
- missing validation:
  - none for current Option A semantics
- missing semantic definition:
  - whether future hardening should preserve the current raw `ValueError` boundary or introduce clearer operator-facing context
- execution justified now: no justified bounded Option A patch remains

## OPTION COMPARISON FOR CANDIDATE 001
- Option A: preserve current raw `ValueError` semantics
  - source evidence: current code uses direct `int()` / `float()` conversion in `settings_from_env`
  - current test evidence: malformed `SEC_LIMIT` and malformed `SEC_SLEEP_SECONDS` now have executable evidence in `tests/test_smoke_local.py`
  - semantic widening: none
  - scope: single-file, single-function
  - risk: low
  - execution-ready now: validation-complete, but no justified bounded patch remains
- Option B: introduce clearer operator-facing config-boundary errors
  - source evidence: current code does not implement this behavior
  - current test evidence: none for message shape or wrapped error semantics
  - semantic widening: yes
  - scope: single-file, single-function is possible, but behavior definition is under-specified
  - risk: higher than Option A
  - execution-ready now: no

## CANDIDATE 002
- source file: `sec_edgar_pipeline/xml_parsers.py`
- target area: `parse_form4_xml_to_json`
- evidence:
  - parser owns real Form 4 extraction logic
  - wrapped-root `xmlData -> ownershipDocument` handling is now executable evidence
  - note still records intentionally partial output and shape-handling limits
- impact scope: single-file, single-function
- classification: single-file
- current maturity: best next validation-expansion candidate
- missing validation:
  - additional XML-shape coverage beyond the wrapped-root and current happy path
  - explicit coverage for the intentionally partial transaction view
- execution justified now: no

## CANDIDATE 003
- source file: `sec_edgar_pipeline/converters.py`
- target area: `convert_local_file_to_markdown`
- evidence:
  - file-type dispatch is a narrow helper boundary
  - non-HTML branches remain outside the current smoke surface
- impact scope: single-file, single-function
- classification: single-file
- current maturity: not execution-ready
- missing validation:
  - PDF / TXT / unsupported-suffix behavior in the local validation surface
- execution justified now: no

## CANDIDATE 004
- source file: `sec_edgar_pipeline/pipeline.py`
- target area: downstream filename trust and result handling
- evidence:
  - file note records trust in `form_map.py` output and lack of second-pass filename checks
  - orchestration behavior is still broader than the current helper-level validation surface
- impact scope: single-file source, but coupled to helper and client behavior
- classification: multi-file risk
- current maturity: not execution-ready
- missing validation:
  - orchestration-level executable validation
- execution justified now: no

## CANDIDATE 005
- source file: `sec_edgar_pipeline/sec_client.py`
- target area: metadata trust and local filename construction
- evidence:
  - file note records raw `filing_date` trust and no audit marker for unknown-form fallback
  - current validation surface does not pin expected behavior here
- impact scope: single-file source, but coupled to upstream SEC metadata behavior
- classification: multi-file risk
- current maturity: not execution-ready
- missing validation:
  - direct executable validation for SEC metadata edge cases
- execution justified now: no
