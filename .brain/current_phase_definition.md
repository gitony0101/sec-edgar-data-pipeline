# CURRENT PHASE DEFINITION

## Phase Name
- control-plane stabilization with repeated verified minimal local patch capability

## Already Implemented
- repository scan and review queue generation are in place
- formal per-file review notes and cross-check notes exist under `review/`
- active control inputs and historical scratch outputs are now explicitly separated
- bootstrap, project architecture, and session memory are defined as three distinct layers
- prompt/persona drift was removed from the active local review scripts
- reviewed cross-check status now survives queue refresh cycles
- two minimal local product-code patches were applied in `sec_edgar_pipeline/form_map.py`
- `python -m pytest -q tests/test_smoke_local.py` passed after each of those two patch rounds
- Phase A through Phase E are now treated as a persistent loop rather than a one-time linear sequence
- default mode is repository reading, understanding, memory update, and suggestion convergence
- bounded execution is treated as candidate-specific exception mode and should return to the loop after completion
- a candidate with no justified bounded patch under current semantics exits the active execution lane cleanly instead of lingering ambiguously

## Not Yet Implemented
- there is no broader validated patch workflow beyond repeated minimal single-file patch trials
- there is no reliable multi-file patch process for local Gemma4
- there is no automated archival policy covering every older `.brain/` experimental artifact
- there is no fully trustworthy regression harness beyond the small local smoke tests currently present

## Allowed In This Phase
- repository scan, file review, and grounded cross-check work
- review/workflow/memory cleanup when it does not break active script readers
- minimal single-file, single-function local patch trials after grounded review evidence exists
- running local smoke tests to validate small changes
- returning from any bounded execution round back into the main reading and suggestion-convergence loop

## Not Allowed In This Phase
- multi-file refactors driven by local Gemma4
- large prompt redesign or workflow redesign
- broad architecture changes to product code
- patch work without grounded review assets and a clear rollback path
- treating scratch artifacts as control-plane inputs
- leaving a closed execution path in an ambiguous "pending execution" state when current semantics no longer justify a bounded patch

## Conditions To Enter The Next Phase
- at least one additional minimal patch trial succeeds without control-plane drift
- the local test environment remains runnable for each patch round
- patch selection remains grounded in formal file notes and cross-check notes
- no active script regressions are introduced by cleanup or prompt-control changes
