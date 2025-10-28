# 📘 Flow Testnet 部署指南

## 🎯 为什么部署到测试网？

1. ✅ **FlowTransactionScheduler 已部署** - 测试网上有完整的 Forte 功能
2. ✅ **免费测试** - 使用 Faucet 获取免费的测试 FLOW
3. ✅ **完整功能演示** - 可以展示定时交易的完整流程
4. ✅ **黑客松认可** - 测试网部署完全有效

## 📋 部署前准备

### 步骤 1: 创建测试网账户

有两种方式创建测试网账户：

#### 方式 A: 使用 Flow CLI（推荐）

```bash
# 生成新的密钥对
flow keys generate

# 输出示例：
# 🔴️ Store private key safely and don't share with anyone! 
# Private Key: abc123...
# Public Key: def456...
```

**保存好私钥！** 然后使用 Flow Faucet 创建账户。

#### 方式 B: 使用 Flow Faucet 网页

1. 访问 [Flow Testnet Faucet](https://testnet-faucet.onflow.org/)
2. 点击 "Create Account"
3. 保存生成的地址和私钥

### 步骤 2: 获取测试 FLOW

访问 [Flow Testnet Faucet](https://testnet-faucet.onflow.org/)，输入你的地址获取测试代币。

建议获取 **至少 10 FLOW** 用于部署和测试。

### 步骤 3: 配置环境变量

```bash
# 复制示例文件
cp .env.testnet.example .env.testnet

# 编辑 .env.testnet，填入你的信息
nano .env.testnet
```

填入内容：
```bash
FLOW_TESTNET_ADDRESS=0x你的测试网地址
FLOW_TESTNET_PRIVATE_KEY=你的私钥（不带0x前缀）
FLOW_TESTNET_KEY_INDEX=0
FLOW_TESTNET_SIGNATURE_ALGORITHM=ECDSA_P256
FLOW_TESTNET_HASH_ALGORITHM=SHA3_256
```

**⚠️ 重要**: 检查你的密钥算法！运行以下命令查看：

```bash
flow accounts get 你的地址 --network testnet
```

查看输出中的 `Signature Algorithm` 和 `Hash Algorithm`，确保与 `.env.testnet` 中的配置一致。

### 步骤 4: 更新 flow.json

```bash
# 编辑 flow.json
nano flow.json
```

更新 `testnet-account` 部分：

```json
{
  "accounts": {
    "testnet-account": {
      "address": "0x你的测试网地址",
      "key": {
        "type": "hex",
        "index": 0,
        "signatureAlgorithm": "ECDSA_P256",
        "hashAlgorithm": "SHA3_256",
        "privateKey": "$FLOW_TESTNET_PRIVATE_KEY"
      }
    }
  }
}
```

**注意**: 使用 `$FLOW_TESTNET_PRIVATE_KEY` 引用环境变量，或者直接填入私钥值。

## 🚀 开始部署

### 方式 A: 使用部署脚本（推荐）

```bash
# 添加执行权限
chmod +x deploy-testnet.sh

# 运行部署脚本
./deploy-testnet.sh
```

### 方式 B: 手动部署

```bash
# 1. 加载环境变量
export $(grep -v '^#' .env.testnet | xargs)

# 2. 验证账户
flow accounts get $FLOW_TESTNET_ADDRESS --network testnet

# 3. 部署合约
flow project deploy --network testnet
```

## ✅ 验证部署

### 1. 查看合约

访问 Flowscan Testnet:
```
https://testnet.flowscan.io/account/你的地址
```

你应该看到两个已部署的合约：
- ✅ `ScheduledSwapHandler`
- ✅ `TradingScheduler`

### 2. 运行测试脚本

```bash
cd examples
node schedule-daily-swap.js
```

### 3. 查询任务状态

```bash
cd examples
node query-task-status.js
```

## 🎬 Demo 演示流程

### 黑客松演示建议

1. **展示合约部署**
   - 在 Flowscan 上展示已部署的合约
   - 说明使用了 Flow Forte 的新特性

2. **演示调度功能**
   - 运行 `schedule-daily-swap.js`
   - 展示定时任务创建成功

3. **查询任务状态**
   - 运行 `query-task-status.js`
   - 展示任务信息和执行历史

4. **说明技术亮点**
   - ✅ 使用 FlowTransactionScheduler 实现自动化
   - ✅ 结合 DeFiActions 进行价格查询
   - ✅ 跨 VM 调用 EVM 合约（概念演示）

## 🔧 故障排查

### 问题 1: 签名错误

```
Error: invalid signature
```

**解决方案**: 检查 `flow.json` 中的签名算法是否与账户匹配。

```bash
# 查看账户信息
flow accounts get 你的地址 --network testnet

# 确保 flow.json 中的算法与输出一致
```

### 问题 2: 余额不足

```
Error: insufficient balance
```

**解决方案**: 访问 Faucet 获取更多测试 FLOW。

### 问题 3: 合约导入失败

```
Error: cannot find declaration
```

**解决方案**: 确保 `flow.json` 中的合约地址正确：
- FlowTransactionScheduler: `0x8c5303eaa26202d6`
- DeFiActions: `0x4c2ff9dd03ab442f`
- BandOracleConnectors: `0x1a9f5d18d096cd7a`

## 📝 关于 EVM 交互

**重要说明**: 

当前版本的合约包含了与 EVM 金库交互的代码，但这部分是**概念演示**：

```cadence
// ScheduledSwapHandler.cdc 中的 EVM 调用
let result = EVM.run(
    to: evmAddress,
    data: callData,
    gasLimit: 1000000,
    value: value
)
```

**对于黑客松 Demo**:
- ✅ 可以展示这段代码说明设计思路
- ✅ 重点演示定时调度功能
- ⚠️ EVM 部分标记为"未来集成"

**如果需要完整的 EVM 集成**:
1. 需要部署 PersonalVault 到 Flow EVM
2. 实现完整的 ABI 编码
3. 处理 EVM 返回值

但这不是必需的！定时调度本身就是很强的功能展示。

## 🎯 总结

完成以上步骤后，你将拥有：

✅ 在 Flow Testnet 上部署的完整合约
✅ 可演示的定时交易功能
✅ 可查询的任务状态
✅ 完整的黑客松展示材料

**测试网部署完全符合黑客松要求！** 🎉

## 📚 相关资源

- [Flow Testnet Faucet](https://testnet-faucet.onflow.org/)
- [Flowscan Testnet](https://testnet.flowscan.io/)
- [Flow CLI 文档](https://developers.flow.com/tools/flow-cli)
- [Forte 教程](https://developers.flow.com/blockchain-development-tutorials/forte)
