#!/usr/bin/env python
from __future__ import annotations

import json
import os
import sys
from collections import Counter, defaultdict
from pathlib import Path

TEXT_EXTS = {
    ".py", ".js", ".ts", ".tsx", ".jsx", ".java", ".go", ".rs", ".rb", ".php",
    ".sh", ".bash", ".zsh", ".ps1", ".md", ".txt", ".rst", ".toml", ".yaml",
    ".yml", ".json", ".ini", ".cfg", ".conf", ".env.example", ".sql", ".html",
    ".css", ".scss", ".lock", ".gitignore", ".dockerignore"
}

NOTEBOOK_EXTS = {".ipynb"}

BINARY_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".pdf", ".zip", ".tar",
    ".gz", ".bz2", ".xz", ".7z", ".mp3", ".mp4", ".mov", ".avi", ".parquet",
    ".feather", ".pkl", ".pickle", ".npy", ".npz", ".onnx", ".bin", ".pt", ".pth"
}

SKIP_DIRS = {
    ".git", ".svn", ".hg", ".idea", ".vscode", "__pycache__", ".mypy_cache",
    ".pytest_cache", ".ruff_cache", ".next", ".nuxt", "node_modules", "dist",
    "build", "target", ".venv", "venv", "env"
}

LOW_PRIORITY_DIR_HINTS = {
    "outputs", "output", "artifacts", "coverage", ".cache", "tmp", "temp",
    "logs", "data", "datasets", "checkpoints", "weights", "models"
}

HIGH_PRIORITY_NAMES = {
    "README.md", "readme.md", "requirements.txt", "pyproject.toml", "package.json",
    "package-lock.json", "poetry.lock", "Pipfile", "Pipfile.lock", "Dockerfile",
    "docker-compose.yml", "docker-compose.yaml", "Makefile", "AGENTS.md"
}

HIGH_PRIORITY_DIRS = {"src", "app", "scripts", "lib", "server", "client", "tests", "test", "config"}

def is_text_like(path: Path) -> bool:
    name = path.name
    if name in HIGH_PRIORITY_NAMES:
        return True
    suffix = path.suffix.lower()
    if suffix in TEXT_EXTS or suffix in NOTEBOOK_EXTS:
        return True
    if name.startswith(".") and suffix in {".yml", ".yaml", ".json", ".toml"}:
        return True
    return False

def classify(path: Path, size_bytes: int) -> tuple[str, str, str]:
    name = path.name
    suffix = path.suffix.lower()
    parts = set(path.parts)

    if name in HIGH_PRIORITY_NAMES:
        return "high", "project-core", "top-level project manifest or documentation"

    if parts & HIGH_PRIORITY_DIRS:
        if suffix in NOTEBOOK_EXTS:
            return "medium", "notebook", "notebook inside a likely important directory"
        if is_text_like(path):
            return "high", "source-or-config", "human-authored source/config in a key directory"

    if parts & LOW_PRIORITY_DIR_HINTS:
        if is_text_like(path):
            return "low", "generated-or-output-text", "text file inside a likely output/data directory"
        return "low", "generated-or-output-binary", "artifact inside a likely output/data directory"

    if suffix in NOTEBOOK_EXTS:
        return "medium", "notebook", "notebook usually needs separate review after core code"

    if suffix in BINARY_EXTS:
        return "low", "binary-or-large-artifact", "binary or analysis artifact"

    if is_text_like(path):
        if size_bytes > 1_500_000:
            return "low", "oversized-text", "text-like file but large; review later in chunks"
        return "medium", "text", "human-authored text file outside the primary code paths"

    return "low", "unknown-or-generated", "unknown extension or likely generated file"

def safe_line_count(path: Path) -> int | None:
    try:
        if path.stat().st_size > 1_500_000:
            return None
        with path.open("r", encoding="utf-8", errors="replace") as f:
            return sum(1 for _ in f)
    except Exception:
        return None

def scan(root: Path) -> list[dict]:
    entries = []

    for current_root, dirs, files in os.walk(root):
        current_path = Path(current_root)
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

        for file_name in files:
            full_path = current_path / file_name
            try:
                rel_path = full_path.relative_to(root)
                stat = full_path.stat()
            except Exception:
                continue

            size_bytes = stat.st_size
            priority, category, reason = classify(rel_path, size_bytes)

            entry = {
                "path": rel_path.as_posix(),
                "name": file_name,
                "suffix": full_path.suffix.lower(),
                "size_bytes": size_bytes,
                "priority": priority,
                "category": category,
                "reason": reason,
                "line_count": safe_line_count(full_path) if is_text_like(full_path) else None,
            }
            entries.append(entry)

    priority_order = {"high": 0, "medium": 1, "low": 2}
    category_order = {
        "project-core": 0,
        "source-or-config": 1,
        "text": 2,
        "notebook": 3,
        "oversized-text": 4,
        "generated-or-output-text": 5,
        "binary-or-large-artifact": 6,
        "generated-or-output-binary": 7,
        "unknown-or-generated": 8,
    }

    entries.sort(
        key=lambda e: (
            priority_order.get(e["priority"], 99),
            category_order.get(e["category"], 99),
            e["path"],
        )
    )
    return entries

def write_outputs(root: Path, entries: list[dict]) -> None:
    out_dir = root / ".codex" / "reports"
    out_dir.mkdir(parents=True, exist_ok=True)

    index_file = out_dir / "repo_scan_index.json"
    summary_file = out_dir / "REPO_SCAN_SUMMARY.md"
    queue_file = out_dir / "REVIEW_QUEUE.md"

    with index_file.open("w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)

    priority_counts = Counter(e["priority"] for e in entries)
    category_counts = Counter(e["category"] for e in entries)

    top_dirs = defaultdict(int)
    for e in entries:
        top = e["path"].split("/", 1)[0]
        top_dirs[top] += 1

    high_entries = [e for e in entries if e["priority"] == "high"]
    medium_entries = [e for e in entries if e["priority"] == "medium"]
    low_entries = [e for e in entries if e["priority"] == "low"]

    with summary_file.open("w", encoding="utf-8") as f:
        f.write("# Repository Scan Summary\n\n")
        f.write(f"- Total files scanned: **{len(entries)}**\n")
        f.write(f"- High priority: **{priority_counts.get('high', 0)}**\n")
        f.write(f"- Medium priority: **{priority_counts.get('medium', 0)}**\n")
        f.write(f"- Low priority: **{priority_counts.get('low', 0)}**\n\n")

        f.write("## Top-level distribution\n\n")
        for name, count in sorted(top_dirs.items(), key=lambda x: (-x[1], x[0]))[:20]:
            f.write(f"- `{name}`: {count}\n")

        f.write("\n## Category distribution\n\n")
        for name, count in sorted(category_counts.items(), key=lambda x: (-x[1], x[0])):
            f.write(f"- `{name}`: {count}\n")

        f.write("\n## Recommended review flow\n\n")
        f.write("1. Review high-priority project docs and manifests\n")
        f.write("2. Review source/config files in key directories\n")
        f.write("3. Review tests\n")
        f.write("4. Review notebooks if they matter to execution or analysis\n")
        f.write("5. Review low-priority outputs or artifacts only if needed\n")

    with queue_file.open("w", encoding="utf-8") as f:
        f.write("# Review Queue\n\n")

        def write_group(title: str, items: list[dict], limit: int) -> None:
            f.write(f"## {title}\n\n")
            if not items:
                f.write("_None_\n\n")
                return
            for i, e in enumerate(items[:limit], 1):
                line_info = f", ~{e['line_count']} lines" if e["line_count"] is not None else ""
                f.write(
                    f"{i}. `{e['path']}`  \n"
                    f"   - category: `{e['category']}`  \n"
                    f"   - reason: {e['reason']}  \n"
                    f"   - size: {e['size_bytes']} bytes{line_info}\n"
                )
            f.write("\n")

        write_group("High priority", high_entries, 50)
        write_group("Medium priority", medium_entries, 50)
        write_group("Low priority", low_entries, 50)

def main() -> int:
    root_arg = sys.argv[1] if len(sys.argv) > 1 else "."
    root = Path(root_arg).resolve()

    if not root.exists() or not root.is_dir():
        print(f"Invalid root directory: {root}", file=sys.stderr)
        return 1

    entries = scan(root)
    write_outputs(root, entries)

    print("Scan complete.")
    print(f"Generated: {root / '.codex' / 'reports' / 'repo_scan_index.json'}")
    print(f"Generated: {root / '.codex' / 'reports' / 'REPO_SCAN_SUMMARY.md'}")
    print(f"Generated: {root / '.codex' / 'reports' / 'REVIEW_QUEUE.md'}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
