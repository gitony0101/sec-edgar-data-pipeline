#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOT'
Usage:
  ./analyze.sh core
  ./analyze.sh file <path>
  ./analyze.sh summary
  ./analyze.sh open <path>
  ./analyze.sh status
  ./analyze.sh list
  ./analyze.sh clean
  ./analyze.sh init-review
  ./analyze.sh review-one <path>
  ./analyze.sh review-next
  ./analyze.sh mark-reviewed <path> [status]
  ./analyze.sh fill-review <path>
  ./analyze.sh build-cross-check-queue
  ./analyze.sh prepare-cross-check-note [file_a file_b]
  ./analyze.sh fill-cross-check-note <path>
  ./analyze.sh mark-cross-check-reviewed <path> [status]
  ./analyze.sh refresh-findings-summary
  ./analyze.sh refresh-project-dashboard
  ./analyze.sh refresh-review-workspace

Modes:
  core        Analyze the current core file set
  file PATH   Analyze a single file and generate one report
  summary     Build a single summary page from current outputs
  open PATH   Print the generated report for one file
  status      Show current tool/output status
  list        Print a compact list of catalog entries
  clean       Remove generated outputs and reset placeholders
  init-review Initialize the review workspace from current artifacts
  review-one PATH Prepare a review note for a single file
  review-next Prepare the next pending file from the queue
  mark-reviewed PATH [STATUS] Mark a file as reviewed or skipped
  fill-review PATH Use local model to fill specific sections of a review note
  build-cross-check-queue Build a cross-check queue from review notes
  prepare-cross-check-note Prepare a cross-check note for a pair of files
  fill-cross-check-note Use local model to fill specific sections of a cross-check note
  mark-cross-check-reviewed PATH [STATUS] Mark a cross-check note as reviewed or skipped
  refresh-findings-summary Aggregates all reviewed notes into FINDINGS.md
  refresh-project-dashboard Generates a top-level review dashboard
  refresh-review-workspace Orchestrates a full refresh of review artifacts
EOT
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

MODE="$1"

case "$MODE" in
  core)
    scripts/analyze_repo_core.sh
    ;;
  file)
    if [ $# -ne 2 ]; then
      usage
      exit 1
    fi
    TARGET="$2"
    scripts/analyze_one.sh "$TARGET"
    ;;
  summary)
    scripts/build_summary.sh
    ;;
  open)
    if [ $# -ne 2 ]; then
      usage
      exit 1
    fi
    TARGET="$2"
    scripts/open_report.sh "$TARGET"
    ;;
  status)
    scripts/status.sh
    ;;
  list)
    scripts/list_catalog.sh
    ;;
  clean)
    scripts/clean_outputs.sh
    ;;
  init-review)
    scripts/init_review.sh
    ;;
  review-one)
    if [ $# -ne 2 ]; then
      usage
      exit 1
    fi
    TARGET="$2"
    scripts/review_one_file_local.sh "$TARGET"
    ;;
  review-next)
    scripts/review_next_file_local.sh
    ;;
  mark-reviewed)
    if [ $# -lt 2 ] || [ $# -gt 3 ]; then
      usage
      exit 1
    fi
    TARGET="$2"
    STATUS="${3:-reviewed}"
    scripts/mark_reviewed_local.sh "$TARGET" "$STATUS"
    ;;
  fill-review)
    if [ $# -ne 2 ]; then
      usage
      exit 1
    fi
    TARGET="$2"
    scripts/fill_review_note_local.sh "$TARGET"
    ;;
  build-cross-check-queue)
    scripts/build_cross_check_queue_local.sh
    ;;
  prepare-cross-check-note)
    if [ $# -eq 1 ]; then
      scripts/prepare_cross_check_note_local.sh
    elif [ $# -eq 3 ]; then
      scripts/prepare_cross_check_note_local.sh "$2" "$3"
    else
      usage
      exit 1
    fi
    ;;
  fill-cross-check-note)
    if [ $# -ne 2 ]; then
      usage
      exit 1
    fi
    scripts/fill_cross_check_note_local.sh "$2"
    ;;
  mark-cross-check-reviewed)
    if [ $# -lt 2 ] || [ $# -gt 3 ]; then
      usage
      exit 1
    fi
    TARGET="$2"
    STATUS="${3:-reviewed}"
    scripts/mark_cross_check_reviewed_local.sh "$TARGET" "$STATUS"
    ;;
  refresh-findings-summary)
    scripts/refresh_findings_summary_local.sh
    ;;
  refresh-project-dashboard)
    scripts/refresh_project_dashboard_local.sh
    ;;
  refresh-review-workspace)
    scripts/refresh_review_workspace_local.sh
    ;;
  *)
    usage
    exit 1
    ;;
esac
