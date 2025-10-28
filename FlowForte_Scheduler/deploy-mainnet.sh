#!/bin/bash

# FlowForte Scheduler - 主网部署脚本
# 安全地从 .env.mainnet 加载环境变量并部署

set -e  # 遇到错误立即退出

echo "========================================="
echo "FlowForte Scheduler - 主网部署"
echo "========================================="
echo ""

# 检查 .env.mainnet 是否存在
if [ ! -f .env.mainnet ]; then
    echo "❌ 错误: .env.mainnet 文件不存在"
    echo "请先运行: cp .env.mainnet.example .env.mainnet"
    exit 1
fi

# 加载环境变量
echo "📋 加载环境变量..."
export $(grep -v '^#' .env.mainnet | xargs)

# 检查必需的环境变量
if [ -z "$FLOW_MAINNET_ADDRESS" ]; then
    echo "❌ 错误: FLOW_MAINNET_ADDRESS 未设置"
    exit 1
fi

if [ -z "$FLOW_MAINNET_PRIVATE_KEY" ]; then
    echo "❌ 错误: FLOW_MAINNET_PRIVATE_KEY 未设置"
    exit 1
fi

echo "✅ 环境变量已加载"
echo "   地址: ${FLOW_MAINNET_ADDRESS:0:10}..."
echo ""

# 备份原始 flow.json
echo "📋 准备配置文件..."
cp flow.json flow.json.backup

# 替换主网环境变量占位符
sed -i.tmp "s/\${FLOW_MAINNET_ADDRESS}/$FLOW_MAINNET_ADDRESS/g" flow.json
sed -i.tmp "s/\${FLOW_MAINNET_PRIVATE_KEY}/$FLOW_MAINNET_PRIVATE_KEY/g" flow.json

# 替换测试网占位符为有效的占位值（避免解析错误）
# Flow 地址必须是 16 个十六进制字符
sed -i.tmp "s/\${FLOW_TESTNET_ADDRESS}/0x0000000000000001/g" flow.json
sed -i.tmp "s/\${FLOW_TESTNET_PRIVATE_KEY}/ae1b44c0f5e8f6992ef2348898a35e50a8b0b9684000da5e1a7b50cc5b8d8c0e/g" flow.json

rm -f flow.json.tmp

echo "✅ 配置文件已更新"
echo ""

# 检查账户余额
echo "📊 检查账户余额..."
flow accounts get $FLOW_MAINNET_ADDRESS --network mainnet

echo ""
echo "⚠️  警告: 即将部署到主网!"
echo "⚠️  这将消耗真实的 FLOW 代币"
echo ""
read -p "确认继续? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ 部署已取消"
    
    # 恢复原始 flow.json
    echo "🔄 恢复原始配置文件..."
    mv flow.json.backup flow.json
    echo "✅ 配置文件已恢复"
    exit 0
fi

echo ""
echo "🚀 开始部署合约到主网..."
echo ""

# 部署合约
if flow project deploy --network mainnet; then
    echo ""
    echo "========================================="
    echo "✅ 部署完成!"
    echo "========================================="
    echo ""
    echo "📝 下一步:"
    echo "1. 记录合约地址: $FLOW_MAINNET_ADDRESS"
    echo "2. 更新 .env.mainnet 中的 TRADING_SCHEDULER_ADDRESS=$FLOW_MAINNET_ADDRESS"
    echo "3. 运行测试: npm run test:mainnet"
    echo ""
    
    # 恢复原始 flow.json
    echo "🔄 恢复原始配置文件..."
    mv flow.json.backup flow.json
    echo "✅ 配置文件已恢复"
else
    echo ""
    echo "❌ 部署失败!"
    echo ""
    
    # 恢复原始 flow.json
    echo "🔄 恢复原始配置文件..."
    mv flow.json.backup flow.json
    echo "✅ 配置文件已恢复"
    exit 1
fi
