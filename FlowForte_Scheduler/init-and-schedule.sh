#!/bin/bash

# Complete workflow: Initialize Manager + Schedule Task

set -e

echo "========================================="
echo "FlowForte Scheduler - Complete Setup"
echo "========================================="
echo ""

# Load environment variables
set -a
source .env.testnet
set +a

# Step 1: Initialize Manager
echo "📋 Step 1: Initialize Manager"
echo "========================================="
echo ""

flow transactions send cadence/transactions/init-manager.cdc \
  --network testnet \
  --signer testnet-account

echo ""
echo "✅ Manager initialized"
echo ""

# Step 2: Schedule Task
echo "📋 Step 2: Schedule Task"
echo "========================================="
echo ""

# Calculate execution time (2 minutes from now)
CURRENT_TIME=$(date +%s)
DELAY_SECONDS=120
EXECUTE_AT=$((CURRENT_TIME + DELAY_SECONDS))

echo "Task Parameters:"
echo "  Vault: 0x0000000000000000000000000000000000000000"
echo "  Token In: FLOW"
echo "  Token Out: USDC"
echo "  Amount: 1.0 FLOW"
echo "  Slippage: 1%"
echo "  Execute in: $DELAY_SECONDS seconds ($(date -r $EXECUTE_AT '+%H:%M:%S'))"
echo "  Priority: Medium (1)"
echo "  Execution Effort: 5000"
echo ""

flow transactions send cadence/transactions/schedule-with-manager.cdc \
  --args-json '[
    {"type":"String","value":"0x0000000000000000000000000000000000000000"},
    {"type":"String","value":"FLOW"},
    {"type":"String","value":"USDC"},
    {"type":"UInt256","value":"1000000000000000000"},
    {"type":"UFix64","value":"0.01"},
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
echo "✅ Complete! Task Scheduled!"
echo "========================================="
echo ""
echo "⏰ Your task will execute in 2 minutes!"
echo ""
echo "📝 Next Steps:"
echo "1. Wait 2 minutes for automatic execution"
echo ""
echo "2. Query task status:"
echo "   ./query-task.sh 2"
echo ""
echo "3. Check Flowscan:"
echo "   https://testnet.flowscan.io/account/$FLOW_TESTNET_ADDRESS"
echo ""
