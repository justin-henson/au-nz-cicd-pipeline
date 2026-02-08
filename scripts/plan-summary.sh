#!/bin/bash
set -euo pipefail

# plan-summary.sh
# Parses Terraform plan output and generates a human-readable summary
# Typically called from CI/CD to post plan summaries as PR comments

# Usage: ./plan-summary.sh <plan_file>

PLAN_FILE="${1:-tfplan}"

if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: Plan file '$PLAN_FILE' not found"
    exit 1
fi

# Convert binary plan to readable format
terraform show -no-color "$PLAN_FILE" > plan_output.txt

# Extract summary statistics
# Count resources by operation type
CREATES=$(grep -c "will be created" plan_output.txt || echo "0")
UPDATES=$(grep -c "will be updated in-place" plan_output.txt || echo "0")
REPLACES=$(grep -c "must be replaced" plan_output.txt || echo "0")
DESTROYS=$(grep -c "will be destroyed" plan_output.txt || echo "0")

# Calculate total changes
TOTAL=$((CREATES + UPDATES + REPLACES + DESTROYS))

echo "==================================="
echo "Terraform Plan Summary"
echo "==================================="
echo "Total changes: $TOTAL"
echo ""
echo "➕ Resources to create:  $CREATES"
echo "🔄 Resources to update:  $UPDATES"
echo "⚠️  Resources to replace: $REPLACES"
echo "❌ Resources to destroy: $DESTROYS"
echo "==================================="
echo ""

# Warn on destructive changes
if [ "$DESTROYS" -gt 0 ] || [ "$REPLACES" -gt 0 ]; then
    echo "⚠️  WARNING: This plan contains destructive changes!"
    echo "Review carefully before applying."
    echo ""
fi

# Extract changed resource addresses for detailed review
echo "Changed resources:"
grep -E "will be created|will be updated|must be replaced|will be destroyed" plan_output.txt | \
    sed 's/^[[:space:]]*//' | \
    head -n 20

if [ "$TOTAL" -gt 20 ]; then
    echo ""
    echo "... and $((TOTAL - 20)) more changes. See full plan for details."
fi

echo ""
echo "Full plan output saved to: plan_output.txt"

# Exit with appropriate code
# 0 = no changes or successful changes
# 1 = only if there was an error (already handled by set -e)
exit 0
