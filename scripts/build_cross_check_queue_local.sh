#!/usr/bin/env python
import os
import re
from pathlib import Path

# scripts/build_cross_check_queue_local.sh
# Scans FILE_NOTES for NEEDS_CROSS_CHECK_WITH and builds a queue.
# Normalizes paths to be repo-relative.

NOTES_DIR = Path("review/FILE_NOTES")
QUEUE_FILE = Path("review/CROSS_CHECK_QUEUE.md")

def load_existing_statuses():
    statuses = {}
    if not QUEUE_FILE.exists():
        return statuses

    with open(QUEUE_FILE, "r") as f:
        for line in f:
            if "| " not in line or "Status" in line or "---" in line:
                continue
            parts = [p.strip() for p in line.split("|")]
            if len(parts) < 5:
                continue
            status, file_a, file_b = parts[1], parts[2], parts[3]
            if not file_a or not file_b or file_a == "-" or file_b == "-":
                continue
            pair = tuple(sorted([file_a, file_b]))
            statuses[pair] = status
    return statuses

def resolve_path(base_file, ref_name):
    """
    Try to resolve a reference name to a repo-relative path.
    1. Check if ref_name exists as is.
    2. Check if ref_name exists relative to the directory of base_file.
    3. Check if ref_name exists relative to the repo root.
    """
    ref_path = Path(ref_name)
    if ref_path.exists() and not ref_path.is_absolute():
        return str(ref_path)
    
    # Try relative to base_file's directory
    base_dir = Path(base_file).parent
    rel_to_base = base_dir / ref_name
    if rel_to_base.exists():
        return str(rel_to_base)
    
    # Try relative to root (already checked by ref_path.exists() but being explicit)
    if Path(ref_name).exists():
        return ref_name
        
    return None

def extract_candidates():
    candidates = []
    if not NOTES_DIR.exists():
        return candidates

    for note_file in NOTES_DIR.glob("*.md"):
        with open(note_file, "r") as f:
            content = f.read()
        
        # Extract FILE_PATH
        path_match = re.search(r"## FILE_PATH\n(.*?)\n", content)
        if not path_match:
            continue
        file_a = path_match.group(1).strip()

        # Extract NEEDS_CROSS_CHECK_WITH section
        cross_match = re.search(r"## NEEDS_CROSS_CHECK_WITH\n(.*?)(?=\n## |\Z)", content, re.DOTALL)
        if not cross_match:
            continue
        
        section_text = cross_match.group(1).strip()
        for line in section_text.splitlines():
            if "Uncertain:" in line or "TODO:" in line:
                continue
            
            # Look for potential file names (simple heuristic)
            potential_bs = re.findall(r"['\"](.*?\.(?:py|md))['\"]|(\b\w+\.(?:py|md)\b)", line)
            for p_tuple in potential_bs:
                raw_b = p_tuple[0] or p_tuple[1]
                if not raw_b:
                    continue
                
                file_b = resolve_path(file_a, raw_b)
                if file_b and file_b != file_a:
                    candidates.append((file_a, file_b, line.strip("- ").strip()))

    return candidates

def main():
    candidates = extract_candidates()
    existing_statuses = load_existing_statuses()
    
    header = "# Cross-Check Queue\n\n| Status | File A | File B | Reason |\n| :--- | :--- | :--- | :--- |\n"
    
    if not candidates:
        with open(QUEUE_FILE, "w") as f:
            f.write(header)
            f.write("| - | - | - | No cross-check candidates found yet. |\n")
        print(f"Queue built: {QUEUE_FILE} (No candidates found)")
        return

    # Normalize and deduplicate
    unique_pairs = {}
    for a, b, reason in candidates:
        # Canonicalize the pair by sorting paths
        pair = tuple(sorted([a, b]))
        if pair not in unique_pairs:
            unique_pairs[pair] = reason

    with open(QUEUE_FILE, "w") as f:
        f.write(header)
        for (a, b), reason in unique_pairs.items():
            status = existing_statuses.get((a, b), "pending")
            f.write(f"| {status} | {a} | {b} | {reason} |\n")
    
    print(f"Queue built: {QUEUE_FILE} ({len(unique_pairs)} pairs found)")

if __name__ == "__main__":
    main()
