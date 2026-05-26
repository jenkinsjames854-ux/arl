#!/usr/bin/env bash
set -euo pipefail

REPO="jenkinsjames854-ux/arl"

if ! gh auth status >/dev/null 2>&1; then
  echo "Authenticate first: gh auth login or set GITHUB_TOKEN with repo scope"
  exit 1
fi

# Dry-run listing of eligible PRs (MERGEABLE + APPROVED)
echo "Eligible PRs (MERGEABLE and APPROVED):"
gh pr list --repo "$REPO" --state open --json number,title,mergeable,reviewDecision --jq '.[] | select(.mergeable=="MERGEABLE" and .reviewDecision=="APPROVED") | "\(.number)\t\(.title)"'

read -p "Proceed to squash-merge these PRs and delete their source branches? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted by user."
  exit 0
fi

pr_numbers=$(gh pr list --repo "$REPO" --state open --json number,mergeable,reviewDecision --jq '.[] | select(.mergeable=="MERGEABLE" and .reviewDecision=="APPROVED") | .number')

if [ -z "$pr_numbers" ]; then
  echo "No eligible PRs found."
  exit 0
fi

for pr in $pr_numbers; do
  echo "Processing PR #$pr..."
  if gh pr merge "$pr" --repo "$REPO" --squash --delete-branch; then
    echo "  Merged #$pr (squash) and deleted branch."
  else
    echo "  Failed to merge #$pr — check branch protection, CI, or conflicts."
  fi
done
