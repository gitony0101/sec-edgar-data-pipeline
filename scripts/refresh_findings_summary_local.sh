#!/usr/bin/env python
import os
import re
from pathlib import Path

# scripts/refresh_findings_summary_local.sh
# Regenerates review/FINDINGS.md from existing reviewed notes.

NOTES_DIR = Path("review/FILE_NOTES")
X_NOTES_DIR = Path("review/CROSS_CHECK_NOTES")
FINDINGS_FILE = Path("review/FINDINGS.md")

def get_status(content, header):
    match = re.search(rf"## {header}\n(.*?)\n", content)
    return match.group(1).strip() if match else "unknown"

def get_section_bullets(content, header, next_header_pattern=r"\n## |\Z"):
    pattern = rf"## {header}\n(.*?)(?={next_header_pattern})"
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return []
    
    lines = match.group(1).strip().splitlines()
    bullets = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        # Skip placeholders
        if any(x in line for x in ["(No ", "TODO:", "Uncertain:", "[ ]"]):
            continue
        bullets.append(line)
    return bullets

def main():
    single_findings = []
    cross_findings = []
    overlap_candidates = []
    cleanup_candidates = []

    # 1. Scan single-file notes
    if NOTES_DIR.exists():
        for note_file in NOTES_DIR.glob("*.md"):
            with open(note_file, "r") as f:
                content = f.read()
            
            status = get_status(content, "REVIEW_STATUS")
            if status in ["reviewed", "skipped"]:
                path_match = re.search(r"## FILE_PATH\n(.*?)\n", content)
                file_path = path_match.group(1).strip() if path_match else note_file.name
                single_findings.append(f"- {file_path} : **{status}**")
                
                # Check for explicit cleanup/overlap
                overlaps = get_section_bullets(content, "POSSIBLE_OVERLAP")
                for o in overlaps:
                    overlap_candidates.append(f"- {file_path}: {o}")
                
                cleanups = get_section_bullets(content, "POSSIBLE_CLEANUP")
                for c in cleanups:
                    cleanup_candidates.append(f"- {file_path}: {c}")

    # 2. Scan cross-check notes
    if X_NOTES_DIR.exists():
        for note_file in X_NOTES_DIR.glob("*.md"):
            with open(note_file, "r") as f:
                content = f.read()
            
            status = get_status(content, "STATUS")
            if status in ["reviewed", "skipped"]:
                file_a = re.search(r"## FILE_A\n(.*?)\n", content).group(1).strip()
                file_b = re.search(r"## FILE_B\n(.*?)\n", content).group(1).strip()
                cross_findings.append(f"- {file_a} vs {file_b} : **{status}**")
                
                # Check for explicit shared concerns/overlaps
                shared = get_section_bullets(content, "POSSIBLE_SHARED_CONCERNS")
                for s in shared:
                    overlap_candidates.append(f"- {file_a} / {file_b}: {s}")

    # 3. Write FINDINGS.md
    with open(FINDINGS_FILE, "w") as f:
        f.write("# Project Review Findings\n\n")
        
        f.write("## Reviewed Single Files\n")
        if single_findings:
            f.write("\n".join(sorted(single_findings)) + "\n")
        else:
            f.write("- No single files reviewed yet.\n")
        
        f.write("\n## Reviewed Cross-Checks\n")
        if cross_findings:
            f.write("\n".join(sorted(cross_findings)) + "\n")
        else:
            f.write("- No cross-checks reviewed yet.\n")
            
        f.write("\n## Overlap & Redundancy Candidates\n")
        if overlap_candidates:
            f.write("\n".join(sorted(set(overlap_candidates))) + "\n")
        else:
            f.write("- None identified yet.\n")
            
        f.write("\n## Cleanup Candidates\n")
        if cleanup_candidates:
            f.write("\n".join(sorted(set(cleanup_candidates))) + "\n")
        else:
            f.write("- None identified yet.\n")

    print(f"Findings refreshed: {FINDINGS_FILE}")

if __name__ == "__main__":
    main()
