# Scripts README

This directory contains the active script chain for the local analysis CLI.

## Main entry flow

- `../analyze.sh`
  Unified CLI entrypoint. Supports core, file, open, list, status, summary, and clean modes.

## Active analysis chain

- `analyze_repo_core.sh`
  Batch-analyzes the current core file set and refreshes the catalog and report index.

- `analyze_one.sh`
  Analyzes one file, classifies it, optionally fetches the first 80 lines, and writes a markdown report.

- `controller_rule_first_v2.sh`
  Main controller for one file. Combines action selection, role classification, logging, and optional fallback checks.

## Deterministic extraction and classification

- `extract_python_card.py`
  Extracts a compact Python evidence card using AST: imports, functions, classes, line count.

- `choose_action_rule_first.sh`
  Rule-first action selector. Currently decides whether current evidence is enough or more code context should be fetched.

- `classify_role_rule_first.sh`
  Rule-first role classifier for known files.

- `get_first_80_lines.sh`
  Returns the first 80 lines of a target file when extra evidence is needed.

## Rendering and reporting

- `render_draft_from_role.sh`
  Produces deterministic two-line draft descriptions from the assigned role label.

- `catalog_append.sh`
  Appends one analyzed file entry into `.brain/FILE_CATALOG.md`.

- `build_summary.sh`
  Builds `.brain/SUMMARY.md` from deterministic outputs.

- `open_report.sh`
  Opens and prints a generated report for a specific file.

- `list_catalog.sh`
  Prints a compact one-line-per-file summary from `.brain/FILE_CATALOG.md`.

- `status.sh`
  Shows current tool status and output presence.

- `clean_outputs.sh`
  Clears generated outputs and recreates minimal placeholders.

## Design principle

Truth comes from deterministic scripts.
Rules make the main decisions.
Model output must not be treated as the source of truth.
