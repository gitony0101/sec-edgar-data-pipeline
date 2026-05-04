# baseline_v1

## Goal
Freeze the first stable local analysis baseline for the SEC EDGAR project.

## What this baseline can do
1. Extract deterministic evidence from files using scripts
2. Classify known file roles with rule-first logic
3. Choose whether extra evidence is needed
4. Log runs into `.brain/RUN_LOG.md`
5. Build a simple file catalog in `.brain/FILE_CATALOG.md`

## What this baseline should NOT do
1. Do not use Gemma for dependency/version extraction
2. Do not use Gemma for long-form review reports
3. Do not use Gemma as the final truth source
4. Do not write model guesses into FACTS

## Current validated file roles
- `sec_edgar_pipeline/__main__.py` -> `python_entrypoint`
- `sec_edgar_pipeline/pipeline.py` -> `core_pipeline_module`
- `sec_edgar_pipeline/sec_client.py` -> `sec_api_client_module`
- `sec_edgar_pipeline/converters.py` -> `conversion_utility_module`

## Current architecture
### Deterministic layer
- file reading
- python card extraction
- rule-first action selection
- rule-first role classification
- logging
- catalog building

### Model layer
- only narrow label-style decisions when needed
- no trusted freeform extraction

## Baseline scripts
- `extract_python_card.py`
- `choose_action_rule_first.sh`
- `classify_role_rule_first.sh`
- `controller_rule_first_v2.sh`
- `catalog_append.sh`
- `get_first_80_lines.sh`

## Next stage candidates
1. Add more role rules
2. Add unknown-file binary fallback checks
3. Add deterministic draft rendering from role labels
4. Build a tiny CLI wrapper for one-command analysis
