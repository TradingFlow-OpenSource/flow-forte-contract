#!/bin/bash

# Schedule IncrementFi swap task

set -e

echo "========================================="
echo "🚀 FlowForte Scheduler + IncrementFi"
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
echo "  Amount In: 1.0 FLOW"
echo "  Min Amount Out: 1.4 USDC"
echo "  Stable Mode: false (volatile pair)"
echo "  Execute in: $DELAY_SECONDS seconds"
echo "  Priority: Medium (1)"
echo "  Execution Effort: 5000"
echo ""

# Step 1: Deploy IncrementFiSwapHandler
echo "📦 Step 1: Deploying IncrementFiSwapHandler..."
echo ""

flow project deploy --network testnet --update

echo ""
echo "✅ Contract deployed"
echo ""

# Step 2: Schedule swap
echo "📋 Step 2: Scheduling IncrementFi swap..."
echo ""

flow transactions send cadence/transactions/schedule-incrementfi-swap.cdc \
  --args-json '[
    {"type":"UFix64","value":"1.0"},
    {"type":"UFix64","value":"1.4"},
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
echo "✅ IncrementFi Swap Scheduled!"
echo "========================================="
echo ""
echo "🎉 Congratulations! You've scheduled a swap on IncrementFi!"
echo ""
echo "📊 What this demonstrates:"
echo "  ✅ Integration with Flow's largest DEX"
echo "  ✅ Real DeFi protocol interaction"
echo "  ✅ Automated swap execution"
echo "  ✅ Flow Forte Scheduled Transactions"
echo ""
echo "⏰ Your swap will execute in 2 minutes!"
echo ""
echo "🔍 Query task status:"
echo "   ./query-task.sh 3"
echo ""
echo "🌐 View on Flowscan:"
echo "   https://testnet.flowscan.io/account/$FLOW_TESTNET_ADDRESS"
echo ""
