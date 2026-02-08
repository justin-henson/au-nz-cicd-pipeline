#!/bin/bash
set -euo pipefail

# notify-drift.sh
# Sends notifications when infrastructure drift is detected
# Supports Slack webhooks and can be extended for email/PagerDuty

# Environment variables expected:
# - DRIFT_DETECTED: "true" if drift was detected
# - CHANGE_COUNT: Number of resources with drift
# - WORKFLOW_URL: URL to the GitHub Actions workflow run
# - SLACK_WEBHOOK_URL: (optional) Slack webhook for notifications

DRIFT_DETECTED="${DRIFT_DETECTED:-false}"
CHANGE_COUNT="${CHANGE_COUNT:-0}"
WORKFLOW_URL="${WORKFLOW_URL:-}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

# Function to send Slack notification
send_slack_notification() {
    local webhook_url="$1"

    if [ -z "$webhook_url" ]; then
        echo "Slack webhook URL not configured, skipping Slack notification"
        return 0
    fi

    # Slack message payload in JSON format
    local payload
    payload=$(cat <<EOF
{
  "text": "🚨 Infrastructure Drift Detected",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🚨 Infrastructure Drift Detected"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Repository:*\nau-nz-cicd-pipeline"
        },
        {
          "type": "mrkdwn",
          "text": "*Resources Affected:*\n${CHANGE_COUNT}"
        },
        {
          "type": "mrkdwn",
          "text": "*Detection Time:*\n$(date -u +"%Y-%m-%d %H:%M UTC")"
        },
        {
          "type": "mrkdwn",
          "text": "*Severity:*\n⚠️ Medium"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*What This Means:*\nThe actual infrastructure state doesn't match the Terraform configuration. This could be due to manual changes, external automation, or AWS-initiated modifications."
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Action Required:*\n1. Review drift details in the workflow run\n2. Determine if drift is expected or needs correction\n3. Update Terraform config or revert manual changes\n4. Run \`terraform apply\` to reconcile"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View Workflow Run"
          },
          "url": "${WORKFLOW_URL}",
          "style": "danger"
        }
      ]
    }
  ]
}
EOF
)

    # Send notification to Slack
    response=$(curl -X POST -H 'Content-type: application/json' \
        --data "$payload" \
        --write-out "%{http_code}" \
        --silent \
        --output /dev/null \
        "$webhook_url")

    if [ "$response" = "200" ]; then
        echo "✅ Slack notification sent successfully"
    else
        echo "❌ Failed to send Slack notification (HTTP $response)"
        return 1
    fi
}

# Function to send email notification (placeholder)
send_email_notification() {
    echo "📧 Email notification (not yet implemented)"
    echo "To implement email notifications, configure AWS SES or integrate with SendGrid/Mailgun"
    echo ""
    echo "Email would contain:"
    echo "- Subject: Infrastructure Drift Detected - ${CHANGE_COUNT} resources"
    echo "- Body: Drift details and link to workflow run"
    echo "- Recipients: DevOps team mailing list"
}

# Main notification logic
if [ "$DRIFT_DETECTED" = "true" ]; then
    echo "=========================================="
    echo "DRIFT DETECTION NOTIFICATION"
    echo "=========================================="
    echo "Drift detected: Yes"
    echo "Resources affected: $CHANGE_COUNT"
    echo "Workflow URL: $WORKFLOW_URL"
    echo "=========================================="
    echo ""

    # Send notifications
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        send_slack_notification "$SLACK_WEBHOOK_URL"
    else
        echo "⚠️  Slack webhook not configured. Set SLACK_WEBHOOK_URL secret to enable Slack notifications."
    fi

    # Email notification placeholder (shows what would be implemented)
    send_email_notification

    echo ""
    echo "✅ Drift notification process complete"
    echo ""
    echo "NEXT STEPS:"
    echo "1. Review drift details at: $WORKFLOW_URL"
    echo "2. A GitHub issue has been automatically created"
    echo "3. Determine if drift requires action or can be ignored"
    echo "4. If action needed: Create PR with Terraform config updates"
else
    echo "ℹ️  No drift detected, no notifications sent"
fi

exit 0
