#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?target required}"
BASE="$(basename "$TARGET")"

if [ "$BASE" = "requirements.txt" ]; then
  echo "1"
  exit 0
fi

if [ "$BASE" = "README.md" ]; then
  echo "2"
  exit 0
fi

if [ "$BASE" = "__main__.py" ]; then
  echo "3"
  exit 0
fi

if [ "$BASE" = "pipeline.py" ]; then
  echo "4"
  exit 0
fi

if [ "$BASE" = "sec_client.py" ]; then
  echo "5"
  exit 0
fi

if [ "$BASE" = "converters.py" ]; then
  echo "6"
  exit 0
fi

if [ "$BASE" = "form_map.py" ]; then
  echo "7"
  exit 0
fi

if [ "$BASE" = "config.py" ]; then
  echo "8"
  exit 0
fi

echo "U"
