#!/bin/bash

# Flow Testnet 部署脚本

set -e

echo "========================================="
echo "Flow Testnet 部署脚本"
echo "========================================="
echo ""

# 检查 .env.testnet 文件
if [ ! -f .env.testnet ]; then
    echo "❌ 错误: .env.testnet 文件不存在"
    echo "请复制 .env.testnet.example 为 .env.testnet 并填入你的配置"
    exit 1
fi

# 加载环境变量
set -a
source .env.testnet
set +a

# 验证必需的环境变量
if [ -z "$FLOW_TESTNET_ADDRESS" ] || [ -z "$FLOW_TESTNET_PRIVATE_KEY" ]; then
    echo "❌ 错误: 缺少必需的环境变量"
    echo "请确保 .env.testnet 中设置了:"
    echo "  - FLOW_TESTNET_ADDRESS"
    echo "  - FLOW_TESTNET_PRIVATE_KEY"
    exit 1
fi

echo "📋 配置信息:"
echo "  账户地址: $FLOW_TESTNET_ADDRESS"
echo "  网络: Testnet"
echo ""

# 检查账户余额
echo "🔍 检查账户余额..."
flow accounts get 0xe41ad2109fdffa04 --network testnet

echo ""
read -p "确认部署到测试网？(y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 部署已取消"
    exit 1
fi

echo ""
echo "========================================="
echo "开始部署合约到测试网..."
echo "========================================="
echo ""

# 部署合约
flow project deploy --network testnet

echo ""
echo "========================================="
echo "✅ 部署完成！"
echo "========================================="
echo ""
echo "📝 后续步骤:"
echo "1. 在 Flowscan Testnet 查看你的合约:"
echo "   https://testnet.flowscan.io/account/$FLOW_TESTNET_ADDRESS"
echo ""
echo "2. 运行示例脚本测试功能:"
echo "   cd examples"
echo "   node schedule-daily-swap.js"
echo ""
