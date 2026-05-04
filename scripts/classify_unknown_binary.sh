#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?target required}"
FACTS_FILE=".brain/UNKNOWN_CARD.md"

python scripts/extract_python_card.py "$TARGET" > "$FACTS_FILE"

codex exec \
  --oss \
  -c oss_provider=ollama \
  -m gemma4:e2b \
  --full-auto \
"Read the facts below.

Task:
Return exactly one character.

Allowed outputs:
Y
N

Question:
Is this file an entrypoint?

Facts:
$(cat "$FACTS_FILE")"
