#!/bin/bash

# Check deployed contracts on testnet

echo "========================================="
echo "📦 FlowForte Scheduler - Deployed Contracts"
echo "========================================="
echo ""

ACCOUNT="0xe41ad2109fdffa04"

echo "🔍 Querying account: $ACCOUNT"
echo ""

flow accounts get $ACCOUNT --network testnet --host access.devnet.nodes.onflow.org:9000 2>&1 | grep -A 10 "Contracts Deployed"

echo ""
echo "========================================="
echo "📋 Contract Details"
echo "========================================="
echo ""
echo "1️⃣  TradingScheduler"
echo "    Address: $ACCOUNT"
echo "    Purpose: Task management and scheduling"
echo ""
echo "2️⃣  ScheduledSwapHandler"
echo "    Address: $ACCOUNT"
echo "    Purpose: Generic swap execution handler"
echo ""
echo "3️⃣  IncrementFiSwapHandler"
echo "    Address: $ACCOUNT"
echo "    Purpose: IncrementFi DEX integration"
echo ""
echo "========================================="
echo "🌐 View on Flowscan:"
echo "    https://testnet.flowscan.io/account/$ACCOUNT"
echo "========================================="
echo ""
