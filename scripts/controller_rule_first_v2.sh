#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?target required}"
LOG_FILE=".brain/RUN_LOG.md"

ACTION="$(scripts/choose_action_rule_first.sh "$TARGET")"
ROLE="$(scripts/classify_role_rule_first.sh "$TARGET")"
UNKNOWN_ENTRYPOINT=""
UNKNOWN_CORE=""

role_label() {
  case "$1" in
    1) echo "dependency_manifest" ;;
    2) echo "project_readme" ;;
    3) echo "python_entrypoint" ;;
    4) echo "core_pipeline_module" ;;
    5) echo "sec_api_client_module" ;;
    6) echo "conversion_utility_module" ;;
    7) echo "form_mapping_utility_module" ;;
    8) echo "configuration_module" ;;
    *) echo "unknown" ;;
  esac
}

if [ "$ROLE" = "U" ]; then
  UNKNOWN_ENTRYPOINT="$(scripts/classify_unknown_binary.sh "$TARGET" | tail -n 1 | tr -d '\r')"
  if [ "$UNKNOWN_ENTRYPOINT" = "Y" ]; then
    ROLE="3"
  else
    UNKNOWN_CORE="$(scripts/classify_unknown_core_binary.sh "$TARGET" | tail -n 1 | tr -d '\r')"
    if [ "$UNKNOWN_CORE" = "Y" ]; then
      ROLE="4"
    fi
  fi
fi

ROLE_LABEL="$(role_label "$ROLE")"

{
  echo "## Run"
  echo "- target: $TARGET"
  echo "- action: $ACTION"
  echo "- role: $ROLE"
  echo "- role_label: $ROLE_LABEL"
  if [ -n "$UNKNOWN_ENTRYPOINT" ]; then
    echo "- unknown_entrypoint_check: $UNKNOWN_ENTRYPOINT"
  fi
  if [ -n "$UNKNOWN_CORE" ]; then
    echo "- unknown_core_check: $UNKNOWN_CORE"
  fi
  if [ "$ACTION" = "2" ]; then
    echo "- extra: first 80 lines fetched"
  else
    echo "- extra: none"
  fi
  echo
} >> "$LOG_FILE"

echo "TARGET=$TARGET"
echo "ACTION=$ACTION"
echo "ROLE=$ROLE"
echo "ROLE_LABEL=$ROLE_LABEL"

if [ -n "$UNKNOWN_ENTRYPOINT" ]; then
  echo "UNKNOWN_ENTRYPOINT_CHECK=$UNKNOWN_ENTRYPOINT"
fi

if [ -n "$UNKNOWN_CORE" ]; then
  echo "UNKNOWN_CORE_CHECK=$UNKNOWN_CORE"
fi

if [ "$ACTION" = "2" ]; then
  echo "---- FIRST 80 LINES ----"
  sed -n '1,80p' "$TARGET"
fi
