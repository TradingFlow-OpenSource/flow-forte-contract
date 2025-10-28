# FlowForte Scheduler - 主网部署指南

## ⚠️ 重要提醒

部署到主网前，请确认：
- ✅ 代码已充分测试
- ✅ 有足够的 FLOW 支付 gas 费
- ✅ 理解主网操作的风险
- ✅ 备份好所有私钥

---

## 📋 部署前准备

### **1. 准备主网账户**

确保你有：
- Flow 主网账户地址
- 账户私钥
- 足够的 FLOW（建议至少 10 FLOW）

### **2. 确认现有资源**

你已经有的主网资源：
- ✅ EVM PersonalVault Factory: `0x486eDaD5bBbDC8eD5518172b48866cE747899D89`
- ✅ EVM PersonalVault Implementation: `0x2E3b9Bb10a643DaDEDe356049e0bfdF0B6aDcd8a`
- ✅ PunchSwap V2 Router: `0xf45AFe28fd5519d5f8C1d4787a4D5f724C0eFa4d`
- ✅ WFLOW: `0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e`

### **3. 查询 Flow Forte 主网合约地址**

需要确认这些系统合约在主网的地址：
- FlowTransactionScheduler
- DeFiActions
- BandOracleConnectors

**查询方法**：
```bash
# 访问 Flow 官方文档
# https://developers.flow.com/build/core-contracts

# 或使用 Flow CLI 查询
flow accounts get 0x... --network mainnet
```

---

## 🔧 配置文件

### **1. 更新 flow.json**

编辑 `flow.json`，添加主网配置：

```json
{
  "contracts": {
    "TradingScheduler": "./cadence/contracts/TradingScheduler.cdc",
    "ScheduledSwapHandler": "./cadence/contracts/TradingScheduler.cdc"
  },
  "networks": {
    "mainnet": "access.mainnet.nodes.onflow.org:9000"
  },
  "accounts": {
    "mainnet-account": {
      "address": "0xYOUR_MAINNET_ADDRESS",
      "key": {
        "type": "hex",
        "index": 0,
        "signatureAlgorithm": "ECDSA_P256",
        "hashAlgorithm": "SHA3_256",
        "privateKey": "YOUR_PRIVATE_KEY"
      }
    }
  },
  "deployments": {
    "mainnet": {
      "mainnet-account": [
        "TradingScheduler",
        "ScheduledSwapHandler"
      ]
    }
  }
}
```

### **2. 配置环境变量**

创建 `.env.mainnet`：

```env
# ========================================
# Flow Mainnet Configuration
# ========================================

# Flow Access Node
FLOW_ACCESS_NODE=https://rest-mainnet.onflow.org

# Flow Account
FLOW_MAINNET_ADDRESS=0x...
FLOW_MAINNET_PRIVATE_KEY=...

# ========================================
# Flow Forte System Contracts (Mainnet)
# ========================================

# 需要查询实际地址
FLOW_TRANSACTION_SCHEDULER_ADDRESS=0x...
DEFI_ACTIONS_ADDRESS=0x...
BAND_ORACLE_CONNECTORS_ADDRESS=0x...

# ========================================
# Deployed Contracts (部署后填写)
# ========================================

TRADING_SCHEDULER_ADDRESS=
SCHEDULED_SWAP_HANDLER_ADDRESS=

# ========================================
# EVM Vault (Mainnet - 已存在)
# ========================================

VAULT_ADDRESS=0x...  # 你的 PersonalVault 地址
FACTORY_ADDRESS=0x486eDaD5bBbDC8eD5518172b48866cE747899D89

# Token Addresses (Flow EVM Mainnet)
WFLOW_ADDRESS=0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e
# 添加其他代币地址...
```

---

## 🚀 部署步骤

### **步骤 1: 检查账户余额**

```bash
# 查询账户余额
flow accounts get 0xYOUR_ADDRESS --network mainnet

# 确保有足够的 FLOW
# 建议至少 10 FLOW（部署 + gas 费）
```

### **步骤 2: 验证合约语法**

```bash
cd FlowForte_Scheduler

# 检查 Cadence 语法
flow cadence lint cadence/contracts/TradingScheduler.cdc
```

### **步骤 3: 部署到主网**

```bash
# 部署合约
flow project deploy --network mainnet

# 输出示例：
# Deploying 2 contracts for accounts: mainnet-account
# 
# TradingScheduler -> 0x1234567890abcdef
# ScheduledSwapHandler -> 0x1234567890abcdef
# 
# ✅ All contracts deployed successfully
```

**重要**：记录部署的合约地址！

### **步骤 4: 验证部署**

```bash
# 查询合约
flow accounts get 0xYOUR_ADDRESS --network mainnet

# 应该看到部署的合约
```

### **步骤 5: 更新环境变量**

编辑 `.env.mainnet`，填写部署的合约地址：

```env
TRADING_SCHEDULER_ADDRESS=0x1234567890abcdef
SCHEDULED_SWAP_HANDLER_ADDRESS=0x1234567890abcdef
```

---

## 🧪 主网测试

### **创建主网测试脚本**

创建 `test-mainnet.js`：

```javascript
const fcl = require("@onflow/fcl");
require("dotenv").config({ path: ".env.mainnet" });

// 配置 FCL 连接主网
fcl.config({
    "accessNode.api": "https://rest-mainnet.onflow.org",
    "discovery.wallet": "https://fcl-discovery.onflow.org/authn",
    "0xTradingScheduler": process.env.TRADING_SCHEDULER_ADDRESS,
});

async function testMainnet() {
    console.log("========================================");
    console.log("FlowForte Scheduler - Mainnet Test");
    console.log("========================================\n");
    
    console.log("⚠️  WARNING: This will use REAL FLOW on MAINNET!");
    console.log("Press Ctrl+C to cancel, or wait 5 seconds to continue...\n");
    
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // 设置 5 分钟后执行（给足够时间观察）
    const executeAt = Math.floor(Date.now() / 1000) + 300;
    
    console.log("📋 Task Configuration:");
    console.log(`Execute At: ${new Date(executeAt * 1000).toISOString()}`);
    console.log(`Vault Address: ${process.env.VAULT_ADDRESS}`);
    console.log(`Amount: 0.1 FLOW (small test)`);
    console.log();
    
    const transaction = `
        import TradingScheduler from ${process.env.TRADING_SCHEDULER_ADDRESS}
        
        transaction(
            vaultAddress: String,
            tokenIn: String,
            tokenOut: String,
            amountIn: UInt256,
            slippage: UFix64,
            executeAt: UFix64,
            frequency: UFix64
        ) {
            prepare(signer: auth(Storage) &Account) {
                log("Scheduling mainnet task...")
                
                let taskId = TradingScheduler.scheduleSwap(
                    vaultAddress: vaultAddress,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: amountIn,
                    slippage: slippage,
                    executeAt: executeAt,
                    recurring: false,
                    frequency: frequency
                )
                
                log("Task scheduled with ID: ".concat(taskId.toString()))
            }
        }
    `;
    
    try {
        console.log("📤 Submitting to MAINNET...");
        
        const txId = await fcl.mutate({
            cadence: transaction,
            args: (arg, t) => [
                arg(process.env.VAULT_ADDRESS, t.String),
                arg("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", t.String), // FLOW
                arg(process.env.WFLOW_ADDRESS, t.String), // WFLOW
                arg("100000000000000000", t.UInt256), // 0.1 FLOW
                arg("0.05", t.UFix64),
                arg(executeAt.toFixed(1), t.UFix64),
                arg("0.0", t.UFix64)
            ],
            proposer: fcl.currentUser,
            payer: fcl.currentUser,
            authorizations: [fcl.currentUser],
            limit: 9999
        });
        
        console.log(`\n✅ Transaction submitted!`);
        console.log(`Transaction ID: ${txId}`);
        console.log(`\n🔗 View on FlowScan MAINNET:`);
        console.log(`https://flowscan.io/transaction/${txId}`);
        
        console.log("\n⏳ Waiting for seal...");
        const result = await fcl.tx(txId).onceSealed();
        
        console.log("\n✅ Transaction sealed!");
        console.log(`\n📊 Events:`);
        result.events.forEach(e => {
            console.log(`  - ${e.type}`);
        });
        
        return txId;
        
    } catch (error) {
        console.error("\n❌ Error:", error);
        throw error;
    }
}

testMainnet()
    .then(txId => {
        console.log("\n========================================");
        console.log("✅ Mainnet test completed!");
        console.log("========================================");
        console.log(`\nView on FlowScan: https://flowscan.io/transaction/${txId}`);
        process.exit(0);
    })
    .catch(error => {
        console.error("\n❌ Test failed:", error.message);
        process.exit(1);
    });
```

### **运行主网测试**

```bash
# 使用主网配置
node test-mainnet.js
```

---

## 📊 在 FlowScan 查看

### **主网 FlowScan**

访问：`https://flowscan.io/transaction/{txId}`

**应该看到**：
1. ✅ Transaction Status: Sealed
2. ✅ Events: `TradingScheduler.TaskScheduled`
3. ✅ Contract: 你部署的合约地址
4. ✅ Event Data: taskId, vaultAddress, tokenIn, tokenOut, etc.

---

## ⚠️ 安全注意事项

### **1. 私钥安全**

```bash
# 永远不要提交 .env.mainnet 到 Git
echo ".env.mainnet" >> .gitignore

# 使用环境变量
export FLOW_MAINNET_PRIVATE_KEY="..."
```

### **2. 小额测试**

第一次测试使用小额：
- 0.1 FLOW 或更少
- 确认功能正常后再增加金额

### **3. 监控执行**

- 设置告警监控任务执行
- 定期检查任务状态
- 准备紧急停止机制

### **4. Gas 管理**

```cadence
// 在交易中设置合理的 gas limit
limit: 9999  // 根据实际需要调整
```

---

## 🔍 故障排查

### **问题 1: 部署失败**

**可能原因**：
- 账户余额不足
- 合约依赖缺失
- 网络连接问题

**解决方案**：
```bash
# 检查余额
flow accounts get 0xYOUR_ADDRESS --network mainnet

# 检查网络
ping access.mainnet.nodes.onflow.org

# 查看详细错误
flow project deploy --network mainnet --log-level debug
```

### **问题 2: 交易失败**

**检查**：
- FlowScan 上的错误信息
- 合约日志
- 账户权限

### **问题 3: EVM 调用失败**

**检查**：
- Vault 地址是否正确
- Bot 是否有 ORACLE_ROLE
- EVM 合约是否在同一网络（主网）

---

## 📝 部署检查清单

部署前确认：

- [ ] flow.json 配置正确
- [ ] .env.mainnet 配置完整
- [ ] 账户有足够 FLOW
- [ ] 私钥安全保存
- [ ] 合约代码已审查
- [ ] 测试脚本准备好
- [ ] 监控方案就绪

部署后确认：

- [ ] 合约成功部署
- [ ] 合约地址已记录
- [ ] FlowScan 可以查看合约
- [ ] 测试交易成功
- [ ] 事件正确触发
- [ ] 文档已更新

---

## 🎯 成功标准

### **最小可行部署**

1. ✅ 合约成功部署到主网
2. ✅ 可以创建调度任务
3. ✅ 在 FlowScan 看到交易
4. ✅ 事件正确记录

### **完整功能**

1. ✅ 所有最小可行部署要求
2. ✅ 定时任务自动执行
3. ✅ 跨 VM 调用 EVM Vault 成功
4. ✅ 交易在 PunchSwap 执行
5. ✅ 循环任务正常工作

---

## 📞 获取帮助

如果遇到问题：

1. **查看文档**
   - Flow 官方文档
   - FlowScan 浏览器
   - 本项目 README

2. **社区支持**
   - Flow Discord
   - Flow Forum
   - GitHub Issues

3. **调试工具**
   - Flow CLI
   - FlowScan
   - 合约日志

---

## 🚀 准备好了吗？

确认以上所有准备工作完成后，执行：

```bash
# 1. 部署合约
flow project deploy --network mainnet

# 2. 记录合约地址
# 3. 更新 .env.mainnet
# 4. 运行测试
node test-mainnet.js

# 5. 在 FlowScan 查看结果
# https://flowscan.io/
```

**祝部署顺利！** 🎉
