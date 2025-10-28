#!/bin/bash

# Create a scheduled task (auto-confirm version)

set -e

echo "========================================="
echo "Creating Scheduled Task..."
echo "========================================="
echo ""

# Load environment variables
set -a
source .env.testnet
set +a

# Calculate execution time (5 minutes from now)
CURRENT_TIME=$(date +%s)
EXECUTE_AT=$((CURRENT_TIME + 300))

echo "📋 Task will execute at: $(date -r $EXECUTE_AT '+%Y-%m-%d %H:%M:%S')"
echo ""

# Send transaction
flow transactions send cadence/transactions/schedule-price-check.cdc \
  --args-json '[
    {"type":"String","value":"0x0000000000000000000000000000000000000000"},
    {"type":"String","value":"FLOW"},
    {"type":"String","value":"USDC"},
    {"type":"UInt256","value":"1000000000000000000"},
    {"type":"UFix64","value":"0.01"},
    {"type":"UFix64","value":"'$EXECUTE_AT'.0"},
    {"type":"Bool","value":false},
    {"type":"UFix64","value":"0.0"}
  ]' \
  --network testnet \
  --signer testnet-account

echo ""
echo "========================================="
echo "✅ Task Created!"
echo "========================================="
echo ""
echo "📝 Query task status:"
echo "   ./query-task.sh 1"
echo ""
echo "🌐 View on Flowscan:"
echo "   https://testnet.flowscan.io/account/$FLOW_TESTNET_ADDRESS"
echo ""
