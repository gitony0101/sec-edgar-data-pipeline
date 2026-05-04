# ROLE / BOOTSTRAP MEMORY

## PURPOSE
- Hold the smallest stable bootstrap context for future review rounds.
- Record what the repository tree alone justifies before deep source review begins.
- Prevent prompt drift by keeping early context factual and boundary-oriented.

## EVIDENCE LEVEL
- source: repository tree and top-level scan only
- source limit: this file must not claim source-level behavior that has not been read

## CURRENT REVIEW STANCE
- stance source: inferred from repository structure, not manually assigned
- current stance: review repository boundaries, orchestration points, and workflow assets conservatively
- fixed persona policy: none
- downstream prompt rule: do not inject a named professional persona from this file into later review prompts

## WHAT THE TREE SUPPORTS
- repository type appears to be a Python SEC EDGAR data pipeline with supporting local review tooling
- likely active product code lives under `sec_edgar_pipeline/`
- likely active review workflow lives under `scripts/`, `review/`, and `.brain/`

## WHAT THE TREE DOES NOT SUPPORT
- precise runtime validation guarantees
- exact failure-handling behavior inside modules
- strong architectural claims about coupling without source review

## INITIAL HIGH-LEVERAGE TARGETS
- sec_edgar_pipeline/pipeline.py
- sec_edgar_pipeline/sec_client.py
- sec_edgar_pipeline/form_map.py
- scripts/local_codex_review.sh

## WRITE / READ CONTRACT
- written by: tree-level bootstrap generation or manual workflow cleanup based on visible repository structure
- read by: review orchestration scripts and humans who need first-pass orientation
- update when: repository shape changes materially, or when the bootstrap file drifts into source-level claims
- do not update when: a normal file-level review only changes source-level findings; those belong in project architecture memory or session memory
