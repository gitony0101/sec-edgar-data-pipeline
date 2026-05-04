# GEMMA4:E2B CAPABILITY BOUNDARY

## Verified Capabilities
- generate repository scans and grounded file-review context when source is visible
- contribute to formal single-file review notes and cross-check notes through controlled workflows
- operate within a stabilized control plane that separates bootstrap, architecture, and session memory
- produce and survive two verified minimal product-code patch rounds in the same boundary file and function family
- pass the current local smoke test suite after each of those minimal patch rounds

## Current Reliable Range
- tree-level and file-level review with grounded evidence
- narrow cross-check reasoning between two already reviewed files
- minimal single-file, single-function patch suggestions and execution when the target boundary is already well-defined
- conservative patch scopes that are easy to inspect and easy to revert

## Current Unreliable Range
- broad autonomous refactors
- multi-file architectural edits
- work that depends on weak or stale scratch prompts
- patch rounds that require complex regression validation beyond the existing local smoke tests
- tasks that ask the model to invent or maintain a named persona

## Roles Gemma4:E2B Can Currently Hold
- grounded repository reviewer
- narrow boundary checker
- minimal patch worker under tight scope and explicit constraints

## Roles Gemma4:E2B Should Not Currently Hold
- autonomous architecture rewriter
- multi-file refactor agent
- owner of long-running workflow memory without human review
- source of truth over visible code and formal review artifacts

## Allowed Patch Granularity
- one file
- one function
- very small boundary hardening or normalization fix
- change size small enough for direct human diff review and fast rollback

## Disallowed Patch Types
- concurrency redesign
- whole-file rewrites
- multi-file linked patches
- large logging or error-handling overhauls
- speculative cleanup without grounded review evidence
- any patch that lacks a runnable local verification step

## Current Project-Specific Evidence
- prompt/persona drift in the active scripts was removed and the control plane was stabilized
- cross-check work clarified that `form_map.py` is the effective Markdown filename safety boundary
- the first minimal patch trial hardened `build_markdown_filename()` by sanitizing `filing_date`
- the second minimal patch trial hardened `build_markdown_filename()` by giving unmapped form types an explicit `Unknown_Form` filename prefix
- `python -m pytest -q tests/test_smoke_local.py` completed successfully after each patch round
