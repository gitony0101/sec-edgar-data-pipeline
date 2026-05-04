# FILE REVIEW NOTE

## FILE_PATH
sec_edgar_pipeline/config.py

## ROLE
configuration_module

## REVIEW_STATUS
reviewed

## FACTS
### sec_edgar_pipeline/config.py

- path: sec_edgar_pipeline/config.py
- line_count: 36
- imports:
  - __future__.annotations
  - os
  - dataclasses.dataclass
  - pathlib.Path
- functions:
  - settings_from_env
- classes:
  - SECSettings

## CURRENT_OBSERVATIONS
- `SECSettings` is the narrow configuration boundary object for runtime parameters consumed by the CLI entrypoint and pipeline.
- `settings_from_env` reads environment variables only and leaves required-field enforcement to the caller instead of enforcing it locally.
- Output directory construction is localized here through `Path(os.getenv("SEC_OUTPUT_DIR", ...))`, which keeps path derivation out of the entrypoint.
- Numeric parsing for `SEC_LIMIT` and `SEC_SLEEP_SECONDS` is eager, so malformed environment values currently raise raw conversion errors here.
- `tests/test_smoke_local.py` now anchors the current malformed `SEC_LIMIT` behavior as executable evidence.
- `tests/test_smoke_local.py` now also anchors the current malformed `SEC_SLEEP_SECONDS` behavior as executable evidence.

## POSSIBLE_OVERLAP
- Responsibility overlaps with `sec_edgar_pipeline/__main__.py` because the CLI merges explicit args with these environment-derived defaults.

## POSSIBLE_CLEANUP
- `settings_from_env` does not wrap integer or float conversion failures, so operator-facing errors for malformed env values are likely to be low-context `ValueError`s.
- The function does not validate whether `cik` or `user_agent` are present; that policy is deferred to the CLI layer.
- The current raw conversion failure behavior is now anchored for both malformed `SEC_LIMIT` and malformed `SEC_SLEEP_SECONDS`.

## NEEDS_CROSS_CHECK_WITH
- sec_edgar_pipeline/__main__.py

## NEXT_ACTION
- Use this file as the environment-boundary reference when judging future config hardening suggestions.
- Keep any future suggestion here single-function and validation-backed, because the current module is small but still user-input-facing.
- Re-evaluate `settings_from_env` first when deciding whether a non-`form_map.py` bounded execution move is now mature enough.

## REVIEW_DECISION
reviewed
