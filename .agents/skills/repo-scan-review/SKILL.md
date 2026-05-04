---
name: repo-scan-review
description: Scan the current repository, generate a grounded review queue, and review files one by one without modifying source files. Use this when the user wants Codex to explore local files by itself before auditing them.
---

# Purpose

This skill helps Codex:
1. scan the repository
2. classify files by review priority
3. generate review artifacts under `.codex/reports/`
4. review one file at a time in a grounded way

# When to use

Use this skill when the user asks to:
- scan a local repository first
- build a review order
- audit files one by one
- avoid manually pasting files into chat

# Workflow

1. Run:

   `python .agents/skills/repo-scan-review/scripts/scan_repo.py .`

2. Read:

   - `.codex/reports/REPO_SCAN_SUMMARY.md`
   - `.codex/reports/REVIEW_QUEUE.md`

3. Tell the user the proposed review order.

4. Unless the user asks otherwise, review exactly one file at a time.

5. For each reviewed file, use this structure:

   1. what this file does
   2. concrete issues
   3. risks
   4. missing validation or error handling
   5. improvement suggestions

# Guardrails

- Do not modify source files during scanning or review.
- You may only write review artifacts under `.codex/reports/`.
- Do not invent hidden files or hidden architecture.
- If a file is very large, inspect it in chunks.
- Prefer human-authored text files before generated assets.
