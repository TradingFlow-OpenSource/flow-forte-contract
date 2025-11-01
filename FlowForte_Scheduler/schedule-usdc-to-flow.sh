#!/bin/bash

# Schedule USDC → FLOW swap task

set -e

echo "========================================="
echo "🚀 FlowForte Scheduler - USDC → FLOW Swap"
echo "========================================="
echo ""

# Load environment variables
set -a
source .env.testnet
set +a

# Calculate execution time (2 minutes from now)
CURRENT_TIME=$(date +%s)
DELAY_SECONDS=120

echo "📋 Task Parameters:"
echo "  DEX: IncrementFi (Flow's largest DEX)"
echo "  Direction: USDC → FLOW (Reverse swap)"
echo "  Amount In: 1.5 USDC"
echo "  Min Amount Out: 0.9 FLOW"
echo "  Stable Mode: false (volatile pair)"
echo "  Execute in: $DELAY_SECONDS seconds"
echo "  Priority: Medium (1)"
echo "  Execution Effort: 5000"
echo ""

echo "🚀 Scheduling USDC → FLOW swap..."
echo ""

flow transactions send cadence/transactions/schedule-incrementfi-swap.cdc \
  --args-json '[
    {"type":"UFix64","value":"1.5"},
    {"type":"UFix64","value":"0.9"},
    {"type":"Bool","value":false},
    {"type":"UFix64","value":"'$DELAY_SECONDS'.0"},
    {"type":"Bool","value":false},
    {"type":"UFix64","value":"0.0"},
    {"type":"UInt8","value":"1"},
    {"type":"UInt64","value":"5000"}
  ]' \
  --network testnet \
  --signer testnet-account

echo ""
echo "========================================="
echo "✅ USDC → FLOW Swap Scheduled!"
echo "========================================="
echo ""
echo "🎉 Congratulations! You've scheduled a reverse swap!"
echo ""
echo "📊 What this demonstrates:"
echo "  ✅ Bidirectional trading (USDC → FLOW)"
echo "  ✅ IncrementFi DEX integration"
echo "  ✅ Automated swap execution"
echo "  ✅ Flow Forte Scheduled Transactions"
echo ""
echo "⏰ Your swap will execute in 2 minutes!"
echo ""
echo "🔍 Query task status:"
echo "   ./query-task.sh 4"
echo ""
echo "🌐 View on Flowscan:"
echo "   https://testnet.flowscan.io/account/$FLOW_TESTNET_ADDRESS"
echo ""
