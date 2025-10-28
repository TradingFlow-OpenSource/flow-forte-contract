#!/bin/bash

# Query all scheduled tasks

echo "========================================="
echo "Querying All Scheduled Tasks"
echo "========================================="
echo ""

# Load environment variables
set -a
source .env.testnet 2>/dev/null || true
set +a

flow scripts execute cadence/scripts/get-all-tasks.cdc \
  --network testnet

echo ""
echo "========================================="
echo "Query Complete"
echo "========================================="
