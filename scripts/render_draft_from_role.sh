#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?target required}"

OUT="$(scripts/controller_rule_first_v2.sh "$TARGET")"

ACTION="$(printf '%s\n' "$OUT" | awk -F= '/^ACTION=/{print $2}' | tail -n 1)"
ROLE_LABEL="$(printf '%s\n' "$OUT" | awk -F= '/^ROLE_LABEL=/{print $2}' | tail -n 1)"

case "$ROLE_LABEL" in
  python_entrypoint)
    echo "DRAFT: This file is the Python entrypoint for the SEC EDGAR pipeline."
    if [ "$ACTION" = "1" ]; then
      echo "DRAFT: Current evidence is sufficient for baseline classification."
    else
      echo "DRAFT: More code context is useful before stronger interpretation."
    fi
    ;;
  core_pipeline_module)
    echo "DRAFT: This file appears to implement the core filing-to-markdown pipeline workflow."
    if [ "$ACTION" = "2" ]; then
      echo "DRAFT: The file is long enough that extra code context was fetched."
    else
      echo "DRAFT: Current evidence is sufficient for baseline classification."
    fi
    ;;
  sec_api_client_module)
    echo "DRAFT: This file appears to implement SEC API client helpers and filing download logic."
    if [ "$ACTION" = "2" ]; then
      echo "DRAFT: Extra code context was fetched because the file is non-trivial in size."
    else
      echo "DRAFT: Current evidence is sufficient for baseline classification."
    fi
    ;;
  conversion_utility_module)
    echo "DRAFT: This file appears to provide file conversion and markdown utility functions."
    if [ "$ACTION" = "2" ]; then
      echo "DRAFT: More code context was fetched before rendering this summary."
    else
      echo "DRAFT: Current evidence is sufficient for baseline classification."
    fi
    ;;
  form_mapping_utility_module)
    echo "DRAFT: This file appears to provide SEC form mapping and filename/path helper utilities."
    if [ "$ACTION" = "2" ]; then
      echo "DRAFT: Extra code context was fetched because the file is moderately sized."
    else
      echo "DRAFT: Current evidence is sufficient for baseline classification."
    fi
    ;;
  configuration_module)
    echo "DRAFT: This file appears to define configuration settings and environment-based setup helpers."
    if [ "$ACTION" = "2" ]; then
      echo "DRAFT: Extra code context was fetched before rendering this summary."
    else
      echo "DRAFT: Current evidence is sufficient for baseline classification."
    fi
    ;;
  dependency_manifest)
    echo "DRAFT: This file is treated as the dependency manifest for the project."
    echo "DRAFT: Dependency facts should come from deterministic extraction only."
    ;;
  project_readme)
    echo "DRAFT: This file is treated as the project readme and usage overview."
    echo "DRAFT: Documentation facts should be read directly from the file content."
    ;;
  *)
    echo "DRAFT: This file role is currently unknown."
    echo "DRAFT: Additional evidence is required before generating a stronger description."
    ;;
esac
