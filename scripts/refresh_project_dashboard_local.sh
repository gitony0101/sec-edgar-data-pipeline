#!/usr/bin/env python
import os
import re
from pathlib import Path

# scripts/refresh_project_dashboard_local.sh
# Generates a top-level Project Review Dashboard.

REVIEW_QUEUE = Path("review/REVIEW_QUEUE.md")
CROSS_QUEUE = Path("review/CROSS_CHECK_QUEUE.md")
FINDINGS_FILE = Path("review/FINDINGS.md")
NEXT_STEPS_FILE = Path("review/NEXT_STEPS.md")
DASHBOARD_FILE = Path("review/PROJECT_DASHBOARD.md")

def get_stats(queue_path):
    stats = {"total": 0, "pending": 0, "in_progress": 0, "reviewed": 0, "skipped": 0}
    if not queue_path.exists():
        return stats
    with open(queue_path, "r") as f:
        for line in f:
            if "| " in line and "Status" not in line and "---" not in line:
                stats["total"] += 1
                if "| pending |" in line: stats["pending"] += 1
                elif "| in_progress |" in line: stats["in_progress"] += 1
                elif "| reviewed |" in line: stats["reviewed"] += 1
                elif "| skipped |" in line: stats["skipped"] += 1
    return stats

def get_recent_activity(log_path, pattern, limit=5):
    if not log_path.exists():
        return []
    activities = []
    with open(log_path, "r") as f:
        for line in f:
            if re.search(pattern, line):
                activities.append(line.strip("- [x] ").strip())
    return activities[-limit:][::-1]

def get_next_suggestion(queue_path, label):
    if not queue_path.exists():
        return f"- No {label} queue found."
    with open(queue_path, "r") as f:
        for line in f:
            if "| pending |" in line:
                parts = [p.strip() for p in line.split("|")]
                if len(parts) >= 4:
                    return f"- Next pending {label}: `{parts[2]}`"
    return f"- No pending {label} items."

def main():
    s_stats = get_stats(REVIEW_QUEUE)
    c_stats = get_stats(CROSS_QUEUE)
    
    recent_s = get_recent_activity(NEXT_STEPS_FILE, r"Finished review of")
    recent_c = get_recent_activity(NEXT_STEPS_FILE, r"Finished cross-check of")
    
    next_s = get_next_suggestion(REVIEW_QUEUE, "single-file")
    next_c = get_next_suggestion(CROSS_QUEUE, "cross-check")

    with open(DASHBOARD_FILE, "w") as f:
        f.write("# Project Review Dashboard\n\n")
        
        f.write("## Single-File Review Status\n")
        f.write(f"- Total: {s_stats['total']}\n")
        f.write(f"- Pending: {s_stats['pending']}\n")
        f.write(f"- In Progress: {s_stats['in_progress']}\n")
        f.write(f"- Reviewed: {s_stats['reviewed']}\n")
        f.write(f"- Skipped: {s_stats['skipped']}\n\n")
        
        f.write("## Cross-Check Review Status\n")
        f.write(f"- Total: {c_stats['total']}\n")
        f.write(f"- Pending: {c_stats['pending']}\n")
        f.write(f"- In Progress: {c_stats['in_progress']}\n")
        f.write(f"- Reviewed: {c_stats['reviewed']}\n")
        f.write(f"- Skipped: {c_stats['skipped']}\n\n")
        
        f.write("## Recently Completed Single Files\n")
        if recent_s:
            for act in recent_s: f.write(f"- {act}\n")
        else:
            f.write("- None recently.\n")
        f.write("\n")
        
        f.write("## Recently Completed Cross-Checks\n")
        if recent_c:
            for act in recent_c: f.write(f"- {act}\n")
        else:
            f.write("- None recently.\n")
        f.write("\n")
        
        f.write("## Findings Snapshot\n")
        f.write(f"- See [FINDINGS.md](./FINDINGS.md) for detailed overlap and cleanup candidates.\n\n")
        
        f.write("## Next Workflow Suggestions\n")
        f.write(f"{next_s}\n")
        f.write(f"{next_c}\n")

    print(f"Dashboard refreshed: {DASHBOARD_FILE}")

if __name__ == "__main__":
    main()
