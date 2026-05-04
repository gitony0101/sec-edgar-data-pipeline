# PROJECT ARCHITECTURE

## PURPOSE
- Hold the stable architecture view after real source files have been read.
- Describe module boundaries and responsibility splits without storing session-by-session churn.
- Act as the canonical architecture reference for later review prompts.

## WRITE / READ CONTRACT
- written by: grounded review rounds that read real source files
- read by: review scripts, humans, and later cross-check work
- update when: source review changes the repository-level responsibility map or boundary decisions
- do not update when: a finding is local to one session and does not change the stable module map

## Purpose
- Download recent SEC EDGAR filings for a target CIK.
- Convert primary filing documents into Markdown outputs.
- Parse Form 4 XML into normalized data structures.

## Runtime Flow
- `sec_edgar_pipeline/__main__.py`: CLI entrypoint that merges explicit args with environment-derived settings and hands execution to the pipeline layer.
- `sec_edgar_pipeline/config.py`: environment-configuration boundary that builds `SECSettings` from process env vars.
- `sec_edgar_pipeline/sec_client.py`: fetch filing metadata and download source documents from SEC endpoints.
- `sec_edgar_pipeline/pipeline.py`: orchestrate file download, conversion, staging, and merged output generation.
- `sec_edgar_pipeline/converters.py`: convert HTML, XML, PDF, and text inputs into Markdown-friendly output.
- `sec_edgar_pipeline/xml_parsers.py`: parse Form 4 XML into normalized JSON-like records.
- `sec_edgar_pipeline/form_map.py`: normalize form names and generate filesystem-safe output names.
- `sec_edgar_pipeline/google_drive.py`: optional integration path kept outside the core runtime.

## Workflow Layer
- `analyze.sh`: shell entrypoint for analysis and review subcommands.
- `scripts/`: active workflow and review automation scripts.
- `review/`: per-file notes, queues, findings, and dashboards for the current review loop.
- `.brain/`: working memory, prompts, reports, and local-model support artifacts.
- `baseline_v1/`: frozen baseline snapshot for older deterministic analysis flow.
- `.archive/`: retired scripts and archived review artifacts.

## Current Risk Concentration
- Core runtime risks:
  - sequential orchestration in `sec_edgar_pipeline/pipeline.py`
  - thin network failure handling in `sec_edgar_pipeline/sec_client.py`
  - external conversion dependency fragility in `sec_edgar_pipeline/converters.py`
- Workflow risks:
  - duplicated or stale review artifacts can confuse queue state
  - memory and dashboard state are split across multiple locations

## Current Boundary Decision
- Treat `sec_edgar_pipeline/` as the active product code.
- Treat `scripts/`, `review/`, and `.brain/` as the active review workflow.
- Treat `baseline_v1/` and `.archive/` as historical context unless a script explicitly points to them.
