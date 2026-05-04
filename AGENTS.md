# AGENTS.md
# Repository Review and Safe Iteration Rules

## Purpose

This repository uses local OSS models (primarily `gemma4:e2b` via Ollama/Codex) to perform grounded repository review, session-based memory accumulation, and very conservative code improvement planning.

**Gemini's Role:** Gemini is NOT the runtime agent for repository tasks. Gemini's role is strictly to create scripts, modify infrastructure, debug the project, and improve the workflow.

**Runtime Agent:** All real repository tasks (review, memory updates, patch generation) are executed ONLY by the local `gemma4:e2b` path.

The primary objective is to build a stable review workflow that:
1. scans repository structure first
2. builds grounded context before file review
3. reviews files one by one (using local `gemma4:e2b`)
4. records verified findings into session memory
5. avoids source edits unless explicitly requested by the user
6. keeps review, memory, and patch decisions strictly separated

This file is the top-level operating contract for repository tasks.

Any agent or developer working in this repository must read and follow this file before performing review, planning, memory updates, or source changes.

---

## Core Operating Principle

Repository work must follow a narrow mainline:

1. scan repository context
2. review one file (via local model)
3. produce grounded analysis
4. append session memory
5. identify at most one low-risk patch candidate
6. stop unless the user explicitly asks for patch generation or source edits

Do not expand scope on your own.
Do not combine too many actions in one round.

### Main Loop vs Secondary Loop

The **main loop** of this repository is:
1. read repository structure and source code incrementally
2. improve grounded repository understanding
3. append or refine factual memory
4. accumulate and improve evidence-backed modification suggestions
5. continue deliberate repository reading so later suggestions become better grounded

The **secondary loop** is:
1. select one already-mature suggestion
2. generate or apply one bounded patch
3. validate it conservatively
4. return to the main loop

Patch execution, approval mechanics, workflow cleanup, and process maintenance are downstream activities. They must not replace the main loop as the dominant objective of the project.

### Phase Loop Rule

This repository operates as a **continuous phase loop**, not a one-time linear pipeline.

The phases are:
1. **Phase A: repository understanding**
2. **Phase B: continuous file-by-file review**
3. **Phase C: continuous memory updates**
4. **Phase D: suggestion convergence**
5. **Phase E: bounded execution only for mature candidates**

These phases do not mean "finish A, then finish B, then finish E and stop."
They mean:
1. build or refresh the repository map
2. keep reading important files in deliberate order
3. keep writing grounded memory
4. keep refining an explicit suggestion pool
5. enter one bounded execution round only when a candidate is truly mature
6. return to the main loop immediately after bounded execution unless the user explicitly redirects the task

The default state of the system is:
- read
- understand
- remember
- refine suggestions

Execution is an exception state, not the normal operating state.

### Anti-Drift Rule

If a round starts spending more effort on patch mechanics, approval rituals, cleanup churn, dashboard maintenance, or process housekeeping than on continuous repository reading, memory improvement, and suggestion refinement, that round has drifted away from the core objective.

When drift is detected, the agent must explicitly correct back toward:
1. reading the next high-value file or boundary module
2. updating grounded memory
3. refining accumulated suggestions using newly read evidence

Do not let micro-patch loops, repeated approval-only cycles, or workflow-maintenance loops become the default operating mode of the repository.

Before stopping any round, explicitly check:
1. did the round improve repository understanding across meaningful files
2. did it improve memory quality
3. did it strengthen or clarify the suggestion pool
4. did it compress the next best path enough that the following round will not need to rediscover it

If the answer is no, the round has likely drifted into local completion rather than serving the main objective.

---

## Mandatory First Step for Repository Review Tasks

For repository review tasks, always begin by establishing global context before deep review.

Required first action:
`python .agents/skills/repo-scan-review/scripts/scan_repo.py .`

Then read:
- `.codex/reports/REPO_SCAN_SUMMARY.md`
- `.codex/reports/REVIEW_QUEUE.md`

If the repository uses additional local review scan scripts (e.g., `scripts/tree_role_probe.sh`), run those only if they are consistent with the rules in this file.

No file-level deep review should begin before repository context is established.

---

## Primary Review Workflow (Runtime Path)

All review work executed by the local model (`gemma4:e2b`) should follow this fixed rhythm:

### Round Structure
1. scan or refresh repository context if needed
2. select one target file
3. read the real source code of that file
4. produce grounded analysis
5. append one session entry to review memory
6. identify at most one low-risk patch candidate
7. stop and wait for user approval before patch generation or application

### Important Constraint
One round should have one dominant objective.

Examples of valid single-round objectives:
- review one file
- append one session memory entry
- propose one low-risk patch candidate
- generate one minimal patch draft

Examples of invalid mixed rounds:
- review file + rewrite architecture memory + patch code + refresh dashboard
- review multiple unrelated files + generate patches + update all memories
- infer patch completion from analysis output

However, "one dominant objective" does not mean "one file and stop by default."
When the mainline objective is repository understanding, memory improvement, or suggestion convergence, a round should continue through multiple important files if that is what the evidence supports.

---

## Source of Truth Hierarchy

When doing repository review, use the following evidence hierarchy:
1. visible repository source code
2. repository scan artifacts
3. file-level review notes
4. session memory
5. prior summaries

If evidence is insufficient, say so explicitly.
Do not invent implementation details.
Do not claim code was reviewed if the actual source text was not read.
Do not claim a patch was applied unless the source file was actually modified and verified.

---

## Review Scope Rules

### Allowed during review
You may:
- inspect repository structure
- inspect source files
- inspect review artifacts
- create or update review outputs under approved review locations
- append session memory
- propose low-risk patch ideas
- draft minimal patches only after explicit user approval

### Not allowed during review
You must not:
- modify application source code without explicit user request
- modify tests without explicit user request
- modify configs without explicit user request
- rewrite docs outside review workflow without explicit user request
- rewrite architecture memory automatically
- convert suggestions into fake completion claims
- generate mock/demo/simulation code and present it as a real patch

### Write boundary
Unless the user explicitly requests source edits, create or update files only under approved review/reporting locations such as:
- `.codex/reports/`
- `review/`
- `.brain/`

If the repository already contains a project-specific review memory location (e.g., `.brain/review_session_memory.md`), use it consistently.

---

## Required Per-File Review Format

For each reviewed file, provide grounded output that includes:
1. what this file does
2. its role in the repository
3. concrete issues
4. risks
5. missing validation or error handling
6. low-risk improvement suggestions

Keep findings tied to visible code.
Prefer specific observations over generic software advice.
If the file is large, inspect in chunks and keep the review grounded in the visible content.

---

## Session Memory Rules

Session memory exists to preserve verified review progress across rounds.

### Session memory must contain
- reviewed file path
- architectural role insight
- concrete findings grounded in reviewed code
- cautious observations about downstream impact

### Session memory must not contain
- unverified patch claims
- guessed architecture rewrites
- speculative conclusions presented as facts
- mixed human commentary and model findings without distinction

### Session memory style
Session memory should be:
- incremental
- append-only unless the user explicitly asks for cleanup
- concise
- factual
- review-oriented
- useful for making the next file review and the next suggestion more grounded than the previous round

Session memory is not:
- roleplay
- persona theater
- prompt decoration
- a substitute for continuing repository reading

The three memory layers must stay distinct:
- bootstrap memory: repository-level boundaries and orientation only
- architecture memory: stable module structure and durable system understanding
- session memory: this round's grounded findings, suggestion maturity, verification results, and unresolved items

Recommended format:
```md
## SESSION NNN
### Reviewed File
- path/to/file.py

### Architecture Insight
- ...

### Concrete Findings
- ...
```

---

## Patch Discipline

Patch work is downstream of review, not part of basic review.

Suggestion work comes before patch work.
The agent must accumulate and refine an explicit suggestion pool while reading the repository.
Each serious candidate should become better grounded as more files are read.
Do not jump directly from local understanding of one file into repository modification unless the candidate is already mature enough under the current evidence and validation surface.

### Before any patch proposal
The following must already exist:
- repository context
- file review grounded in real source
- session memory entry for that review round

### Patch rules
- propose at most one patch candidate at a time
- prefer the smallest high-confidence patch
- prefer validation, parsing, cleanup, error handling, or boundary hardening
- patch scope must be local and easy to verify
- do not combine multiple speculative improvements into one patch round

### Patch application rules
- Do not apply a patch unless the user explicitly asks for it.
- Do not describe a patch as completed unless it has been actually written to the source file.
- Do not infer success from a model suggestion alone.

After any bounded patch round, return to the main loop unless the user explicitly requests continued patch execution.

---

## Preferred Patch Candidate Types

Early-stage safe patches should prioritize:
- clearer validation
- more explicit parsing failures
- error handling around I/O
- external dependency checks
- safer temporary file cleanup
- tighter boundary checks for inputs already used by the code

Avoid early large-scale changes such as:
- full-file rewrites
- architectural rewrites
- abstraction refactors
- framework migration
- speculative performance rewrites
- broad async/concurrency redesign

---

## Review Ordering Guidance

Default review order:
1. README and top-level docs
2. dependency and package manifests
3. configuration files
4. boundary modules and integration modules
5. orchestration modules
6. transformation and parsing modules
7. core source modules
8. tests
9. notebooks
10. generated artifacts and caches only if explicitly requested

When a global scan or repository context suggests a different high-leverage order, follow the grounded priority instead of the default list.

Boundary modules are high-value review targets because they often expose:
- I/O semantics
- dependency assumptions
- error handling gaps
- external API surface
- path and state handling issues

The purpose of this reading order is cumulative understanding, not isolated commentary. Each reviewed file should improve future memory quality and sharpen later modification suggestions.

---

## Hard Lessons from This Repository Workflow

The following lessons are considered operational rules for future rounds.

1. **Real source code is required for real review**
   Facts-only notes are useful for indexing and note filling, but real improvement suggestions require reading the actual source text.

2. **Source-first prompting is critical for small local models**
   For small models, first-screen visibility matters more than prompt bulk. Put the target source code early and keep prompts tight.

3. **Global context improves single-file review quality**
   Review quality improves when the model sees repository tree, file list, and minimal architecture context before single-file deep review.

4. **Prompt overload causes drift**
   Long prompts increase the chance of file drift, meta-talk, and format noncompliance. Keep prompts lean.

5. **Role stability should be model-led, not manually overwritten each round**
   Do not repeatedly hard-assign a new review persona if the workflow already established a stable review mode.

6. **One round, one main target**
   Mixing review, memory rewrite, patching, and dashboard updates causes confusion and contaminates state.

7. **Small models are better at analysis than broad refactor execution**
   Use local small models mainly for finding issues and prioritizing risks. Do not rely on them for large autonomous rewrites.

---

## Explicit Do Not Rules

Agents must not:
- pretend a patch was applied
- rewrite source code without permission
- rewrite architecture memory automatically
- mix analysis with fake execution claims
- produce placeholder/mock code and present it as a real patch
- perform batch patching across multiple files without explicit user approval
- silently broaden task scope
- replace grounded review with generic best-practice essays

---

## Required Behavior Before Any Task

Before executing any infrastructure or debug task, Gemini must:
1. read AGENTS.md
2. determine whether the requested action is infrastructure development, debugging, or workflow improvement
3. ensure the task plan complies with the rules in this file
4. refuse internal scope drift
5. keep outputs aligned with the current round objective

If the requested workflow conflicts with this file, the agent should follow the user's explicit instruction only where clearly requested, and otherwise remain conservative.

---

## Output Style for Repository Work

Repository-task outputs should be:
- direct
- concrete
- grounded in visible evidence
- low on meta-talk
- explicit about uncertainty
- explicit about what was reviewed versus what was not reviewed

Avoid generic praise, inflated confidence, or vague "ready to refactor" language without evidence.

---

## Summary Rule

The repository review workflow is:
**scan first -> review one file -> record one session -> propose one small next step -> stop**

That fixed rhythm takes priority over speed, breadth, and premature automation.
