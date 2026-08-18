#!/usr/bin/env bash
# git_push_plots.sh — commit and push the analysis figures.
#
# Usage:
#   cd /path/to/smart_contract_research
#   bash Analysis/plots/git_push_plots.sh

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "=== Adding Analysis/plots/ ==="
git add Analysis/plots/*.png Analysis/plots/generate_vuln_efficiency_plots.py

if git diff --cached --quiet; then
  echo "Nothing to commit — plots are already up to date."
  exit 0
fi

echo
echo "=== Staged ==="
git diff --cached --name-only

echo
echo "=== Committing ==="
git commit -m "Update vulnerability tool efficiency plots (B01-B05)

Regenerated from the five vulnerability_tool_efficiency_report_batchXX.xlsx
reports via Analysis/plots/generate_vuln_efficiency_plots.py."

echo
echo "=== Pushing to origin/main ==="
git push origin main

echo
echo "Done: https://github.com/Gamannn/smart_contract_research/tree/main/Analysis/plots"
