#!/usr/bin/env bash
# Helper for reading/writing the blue/green active-environment state from the CLI.
# Mirrors what the daily-repave GitHub Actions workflow does via `aws dynamodb`.
# Usage:
#   ./scripts/state.sh get
#   ./scripts/state.sh set <blue|green>

set -euo pipefail

TABLE_NAME="blue-green-repave-state"
AWS_REGION="${AWS_REGION:-us-east-1}" # TODO: set to your region

cmd="${1:-}"

case "$cmd" in
  get)
    aws dynamodb get-item \
      --table-name "$TABLE_NAME" \
      --key '{"pk": {"S": "env-state"}}' \
      --region "$AWS_REGION"
    ;;
  set)
    env="${2:-}"
    if [[ "$env" != "blue" && "$env" != "green" ]]; then
      echo "Usage: $0 set <blue|green>" >&2
      exit 1
    fi
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    aws dynamodb put-item \
      --table-name "$TABLE_NAME" \
      --item "{\"pk\": {\"S\": \"env-state\"}, \"active_env\": {\"S\": \"$env\"}, \"last_repaved_at\": {\"S\": \"$now\"}}" \
      --region "$AWS_REGION"
    ;;
  *)
    echo "Usage: $0 {get|set <blue|green>}" >&2
    exit 1
    ;;
esac
