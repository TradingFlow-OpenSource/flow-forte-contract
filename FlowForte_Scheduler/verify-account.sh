#!/bin/bash

# 验证账户配置

echo "========================================="
echo "验证 Flow 主网账户配置"
echo "========================================="
echo ""

# 加载环境变量
if [ -f .env.mainnet ]; then
    export $(grep -v '^#' .env.mainnet | xargs)
fi

if [ -z "$FLOW_MAINNET_ADDRESS" ]; then
    echo "❌ 错误: FLOW_MAINNET_ADDRESS 未设置"
    exit 1
fi

echo "📋 账户地址: $FLOW_MAINNET_ADDRESS"
echo ""

echo "🔍 查询账户信息..."
flow accounts get $FLOW_MAINNET_ADDRESS --network mainnet

echo ""
echo "========================================="
echo "提示:"
echo "========================================="
echo "1. 检查账户是否存在"
echo "2. 检查余额是否充足（≥ 10 FLOW）"
echo "3. 检查 Public Keys 部分"
echo "   - Index 应该是 0"
echo "   - Signing Algorithm 应该是 ECDSA_P256"
echo "   - Hashing Algorithm 应该是 SHA3_256"
echo "   - 确认 Public Key 与你的私钥匹配"
echo ""
