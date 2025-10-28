#!/bin/bash

# 验证测试网配置

echo "========================================="
echo "验证 Flow 测试网配置"
echo "========================================="
echo ""

# 检查 .env.testnet 文件
if [ ! -f .env.testnet ]; then
    echo "❌ 错误: .env.testnet 文件不存在"
    echo "请先创建并配置 .env.testnet 文件"
    exit 1
fi

# 加载环境变量
export $(grep -v '^#' .env.testnet | xargs)

# 验证必需的环境变量
if [ -z "$FLOW_TESTNET_ADDRESS" ]; then
    echo "❌ 错误: FLOW_TESTNET_ADDRESS 未设置"
    exit 1
fi

if [ -z "$FLOW_TESTNET_PRIVATE_KEY" ]; then
    echo "❌ 错误: FLOW_TESTNET_PRIVATE_KEY 未设置"
    exit 1
fi

echo "✅ 环境变量配置正确"
echo ""
echo "📋 配置信息:"
echo "  地址: $FLOW_TESTNET_ADDRESS"
echo "  密钥索引: ${FLOW_TESTNET_KEY_INDEX:-0}"
echo "  签名算法: ${FLOW_TESTNET_SIGNATURE_ALGORITHM:-ECDSA_P256}"
echo "  哈希算法: ${FLOW_TESTNET_HASH_ALGORITHM:-SHA3_256}"
echo ""

echo "🔍 查询账户信息..."
echo ""

flow accounts get $FLOW_TESTNET_ADDRESS --network testnet

echo ""
echo "========================================="
echo "✅ 配置验证完成"
echo "========================================="
echo ""
echo "📝 请检查上面的输出:"
echo "1. 账户是否存在"
echo "2. 余额是否充足（建议 ≥ 10 FLOW）"
echo "3. 密钥算法是否与 .env.testnet 中的配置一致"
echo ""
echo "如果一切正常，运行以下命令部署:"
echo "  ./deploy-testnet.sh"
echo ""
