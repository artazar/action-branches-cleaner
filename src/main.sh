#!/bin/env bash

##
# Determine the project root path. In the normal GitHub Action runtime this is
# provided via the `BRANCHES_CLEANER_HOME` environment variable, but when the
# scripts are sourced directly (e.g. during unit tests) this variable might not
# be defined.  In that case fall back to resolving the path relative to this
# file.
##

if [ -z "${BRANCHES_CLEANER_HOME:-}" ]; then
  BRANCHES_CLEANER_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
fi

# shellcheck source=src/github.sh
# shellcheck disable=SC1091
source "$BRANCHES_CLEANER_HOME"/src/github.sh
# shellcheck source=src/cleanup.sh  
# shellcheck disable=SC1091
source "$BRANCHES_CLEANER_HOME"/src/cleanup.sh

main() {
  BASE_BRANCHES_STR=$1
  DAYS_OLD_THRESHOLD=$2
  DELETE_UNMERGED_PRS=${3:-true}
  DRY_RUN=${4:-false}
  GITHUB_TOKEN=$5

  GITHUB_API_URL="https://api.github.com/repos/$GITHUB_REPOSITORY"

  export GITHUB_TOKEN
  export GITHUB_API_URL
  export DRY_RUN

  IFS=',' read -ra BASE_BRANCHES <<<"$BASE_BRANCHES_STR"

  export BASE_BRANCHES

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "=========================================="
    echo "DRY RUN MODE - No branches will be deleted"
    echo "=========================================="
  fi

  # Load last run timestamp from state file
  local last_run_timestamp=""
  if [[ -f ".branch-cleaner-state" ]]; then
    last_run_timestamp=$(cat .branch-cleaner-state)
    echo "Last run timestamp: $last_run_timestamp ($(date -d "$last_run_timestamp" 2>/dev/null || date -r $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_run_timestamp" +%s 2>/dev/null) 2>/dev/null || echo "unknown"))"
  else
    echo "No previous run found, processing all PRs"
  fi

  export LAST_RUN_TIMESTAMP="$last_run_timestamp"

  closed_prs=$(github::get_closed_prs)

  merged_prs=$(github::get_merged_prs)

  not_merged_prs=$(comm -23 <(echo "$closed_prs" | sort) <(echo "$merged_prs" | sort))

  cleanup::delete_merged_branches "$merged_prs"

  if [[ "$DELETE_UNMERGED_PRS" == "true" ]]; then
    cleanup::delete_unmerged_branches "$not_merged_prs"
  else
    echo "Skipping deletion of unmerged PR branches (delete_unmerged_prs=false)"
  fi

  cleanup::delete_inactive_branches "$DAYS_OLD_THRESHOLD"

  # Save current timestamp for next run
  date -u +"%Y-%m-%dT%H:%M:%SZ" > .branch-cleaner-state
  echo "Saved current timestamp for next run"
}
