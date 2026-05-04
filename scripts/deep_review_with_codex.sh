#!/usr/bin/env bash
set -euo pipefail

# scripts/deep_review_with_codex.sh
# Performs a deep structural and logic review of a single file using codex.

TARGET_FILE="${1:?Error: target file path required}"
MODEL="${MODEL:-gemma4:e2b}"
TMP_DIR=".brain/codex_deep_review"
PROMPT_FILE="$TMP_DIR/deep_review_prompt_$(basename "$TARGET_FILE").txt"

mkdir -p "$TMP_DIR"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "Error: file '$TARGET_FILE' not found."
  exit 1
fi

echo "== Deep Review for: $TARGET_FILE =="

echo "== Building codex prompt =="
cat > "$PROMPT_FILE" <<EOF
You are a senior security-focused software engineer performing a deep code review.

File to review: $TARGET_FILE

Your task:
1. Explain the primary responsibility of this file.
2. Analyze the logic for potential bugs, edge cases, or performance bottlenecks.
3. Identify security risks (e.g., command injection, path traversal, unsafe deserialization).
4. Provide a list of concrete, CONSERVATIVE improvement suggestions.
5. Do NOT modify the file yet.

Source Code:
\`\`\`python
$(cat "$TARGET_FILE")
\`\`\`

Output format:
1. RESPONSIBILITY SUMMARY
2. LOGIC & PERFORMANCE ANALYSIS
3. SECURITY AUDIT
4. CONSERVATIVE IMPROVEMENT SUGGESTIONS
EOF

echo "Saved prompt to: $PROMPT_FILE"
echo

echo "== Running codex deep review with local model =="
codex exec \
  --oss \
  -c oss_provider=ollama \
  -m "$MODEL" \
  "$(cat "$PROMPT_FILE")"
