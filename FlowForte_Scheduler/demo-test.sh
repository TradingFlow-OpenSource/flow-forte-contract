#!/bin/bash

# Demo Test Script - Schedule a task to execute in 5 minutes

set -e

echo "========================================="
echo "FlowForte Scheduler - Demo Test"
echo "========================================="
echo ""

# Load environment variables
set -a
source .env.testnet
set +a

# Calculate execution time (5 minutes from now)
CURRENT_TIME=$(date +%s)
EXECUTE_AT=$((CURRENT_TIME + 300))  # 300 seconds = 5 minutes

echo "📋 Task Parameters:"
echo "  Vault Address: 0x0000000000000000000000000000000000000000 (demo)"
echo "  Token In: FLOW"
echo "  Token Out: USDC"
echo "  Amount In: 1.0 FLOW (1000000000000000000 wei)"
echo "  Slippage: 1% (0.01)"
echo "  Execute At: $EXECUTE_AT ($(date -r $EXECUTE_AT '+%Y-%m-%d %H:%M:%S'))"
echo "  Recurring: false (one-time execution)"
echo "  Frequency: 0 (not recurring)"
echo ""

read -p "Create this scheduled task? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

echo ""
echo "========================================="
echo "Creating Scheduled Task..."
echo "========================================="
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
echo "📝 Next Steps:"
echo "1. Query task status:"
echo "   ./query-task.sh 1"
echo ""
echo "2. Wait for execution (5 minutes)"
echo ""
echo "3. Check Flowscan for transaction:"
echo "   https://testnet.flowscan.io/account/$FLOW_TESTNET_ADDRESS"
echo ""
