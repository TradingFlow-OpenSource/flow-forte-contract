#!/bin/bash

# FlowForte Scheduler - 主网配置助手
# 这个脚本会帮你一步步配置主网部署

echo "=========================================="
echo "FlowForte Scheduler - 主网配置助手"
echo "=========================================="
echo ""

# 检查是否已有配置
if [ -f ".env.mainnet" ]; then
    echo "⚠️  发现已存在的 .env.mainnet 文件"
    read -p "是否覆盖？(y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
        echo "取消配置"
        exit 0
    fi
fi

echo "让我们开始配置主网部署..."
echo ""

# 步骤 1: Flow 账户地址
echo "📝 步骤 1/3: Flow 主网账户"
echo "----------------------------------------"
echo "你需要一个 Flow 主网账户地址"
echo "格式示例: 0x1234567890abcdef"
echo ""
read -p "请输入你的 Flow 主网地址: " flow_address

# 验证地址格式
if [[ ! $flow_address =~ ^0x[0-9a-fA-F]{16}$ ]]; then
    echo "❌ 地址格式不正确！应该是 0x 开头，后面跟 16 个十六进制字符"
    echo "示例: 0x1234567890abcdef"
    exit 1
fi

echo "✅ 地址格式正确"
echo ""

# 步骤 2: 私钥
echo "📝 步骤 2/3: Flow 账户私钥"
echo "----------------------------------------"
echo "⚠️  私钥是敏感信息，请确保安全！"
echo "格式: 64 个十六进制字符（不需要 0x 前缀）"
echo ""
read -sp "请输入你的私钥（输入时不显示）: " private_key
echo ""

# 验证私钥格式
if [[ ! $private_key =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "❌ 私钥格式不正确！应该是 64 个十六进制字符"
    exit 1
fi

echo "✅ 私钥格式正确"
echo ""

# 步骤 3: PersonalVault 地址
echo "📝 步骤 3/3: PersonalVault 地址"
echo "----------------------------------------"
echo "你的 EVM PersonalVault 合约地址"
echo "格式示例: 0x1234567890123456789012345678901234567890"
echo "如果暂时没有，可以输入测试地址: 0x0000000000000000000000000000000000000000"
echo ""
read -p "请输入 Vault 地址: " vault_address

# 验证 EVM 地址格式
if [[ ! $vault_address =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo "❌ EVM 地址格式不正确！应该是 0x 开头，后面跟 40 个十六进制字符"
    echo "示例: 0x1234567890123456789012345678901234567890"
    exit 1
fi

echo "✅ Vault 地址格式正确"
echo ""

# 创建 .env.mainnet 文件
echo "📝 创建配置文件..."
cat > .env.mainnet << EOF
# ========================================
# Flow Mainnet Configuration
# 由 setup-mainnet.sh 自动生成
# ========================================

# Flow 主网账户
FLOW_MAINNET_ADDRESS=$flow_address
FLOW_MAINNET_PRIVATE_KEY=$private_key

# 合约地址（部署后会自动更新）
TRADING_SCHEDULER_ADDRESS=$flow_address

# EVM Vault
VAULT_ADDRESS=$vault_address

# Token 地址（Flow EVM Mainnet）
WFLOW_ADDRESS=0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e

# Flow Access Node
FLOW_ACCESS_NODE=https://rest-mainnet.onflow.org
EOF

echo "✅ 配置文件创建成功！"
echo ""

# 检查账户余额
echo "🔍 检查账户余额..."
balance=$(flow accounts get $flow_address --network mainnet 2>&1 | grep "Balance:" | awk '{print $2}')

if [ -z "$balance" ]; then
    echo "⚠️  无法查询账户余额，请手动检查："
    echo "   flow accounts get $flow_address --network mainnet"
else
    echo "✅ 账户余额: $balance FLOW"
    
    # 检查余额是否足够
    if (( $(echo "$balance < 5" | bc -l) )); then
        echo "⚠️  警告：余额可能不足！建议至少有 10 FLOW"
        echo "   部署合约大约需要 1-2 FLOW"
        echo "   测试交易需要额外的 FLOW"
    else
        echo "✅ 余额充足，可以开始部署"
    fi
fi

echo ""
echo "=========================================="
echo "✅ 配置完成！"
echo "=========================================="
echo ""
echo "📝 配置文件已保存到: .env.mainnet"
echo ""
echo "🚀 下一步："
echo "   1. 检查配置: cat .env.mainnet"
echo "   2. 部署合约: flow project deploy --network mainnet"
echo "   3. 运行测试: npm run test:mainnet"
echo ""
echo "💡 提示："
echo "   - .env.mainnet 包含私钥，请勿分享或提交到 Git"
echo "   - 部署前确保账户有足够的 FLOW（建议 10+ FLOW）"
echo "   - 首次测试使用小额（0.1 FLOW）"
echo ""
