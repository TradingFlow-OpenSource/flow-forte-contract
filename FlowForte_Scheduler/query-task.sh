#!/bin/bash

# Query task status by task ID

if [ -z "$1" ]; then
    echo "Usage: ./query-task.sh <taskId>"
    echo "Example: ./query-task.sh 1"
    exit 1
fi

TASK_ID=$1

echo "========================================="
echo "Querying Task #$TASK_ID"
echo "========================================="
echo ""

# Load environment variables
set -a
source .env.testnet 2>/dev/null || true
set +a

flow scripts execute cadence/scripts/get-task.cdc \
  --args-json '[{"type":"UInt64","value":"'$TASK_ID'"}]' \
  --network testnet

echo ""
echo "========================================="
echo "Query Complete"
echo "========================================="
