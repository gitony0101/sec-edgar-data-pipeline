#!/usr/bin/env bash
set -euo pipefail

TARGET="$1"
sed -n '1,80p' "$TARGET"
