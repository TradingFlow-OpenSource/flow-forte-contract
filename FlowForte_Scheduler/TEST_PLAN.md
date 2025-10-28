# FlowForte Scheduler 测试计划

## 🎯 测试目标

创建一个定时交易任务，在 FlowScan 上可以看到：
1. 调度交易（创建任务）
2. 执行交易（定时触发）
3. 事件记录

---

## 📍 部署选择

### **推荐：Testnet 测试**

**原因**：
- Flow Forte 的 Scheduled Transactions 和 Flow Actions 在 Testnet 上完全可用
- 安全，不会损失真实资金
- 可以快速迭代调试
- FlowScan Testnet 可以查看所有交易

**注意**：
- EVM PersonalVault 在主网，但我们可以在 Testnet 部署一个测试版本
- 或者使用模拟的 EVM 调用（不实际执行 swap）

### **可选：Mainnet 部署**

**仅在以下情况使用**：
- Testnet 测试完全通过
- 准备正式演示
- 愿意承担真实资金风险

---

## 🚀 测试步骤（Testnet）

### **步骤 1：准备环境**

#### 1.1 获取 Testnet 账户

```bash
# 如果还没有 Flow Testnet 账户
flow keys generate

# 到 Testnet Faucet 领取测试币
# https://testnet-faucet.onflow.org/
```

#### 1.2 配置环境变量

```bash
cd FlowForte_Scheduler
cp .env.example .env
```

编辑 `.env`：

```env
# Flow Testnet 配置
FLOW_ACCESS_NODE=https://rest-testnet.onflow.org
FLOW_TESTNET_ADDRESS=0x...        # 你的 Testnet 地址
FLOW_TESTNET_PRIVATE_KEY=...      # 你的私钥

# 合约地址（部署后填写）
TRADING_SCHEDULER_ADDRESS=
SCHEDULED_SWAP_HANDLER_ADDRESS=

# Flow 系统合约（Testnet）
FLOW_TRANSACTION_SCHEDULER_ADDRESS=0x...  # 需要查询 Forte 文档
DEFI_ACTIONS_ADDRESS=0x...
BAND_ORACLE_CONNECTORS_ADDRESS=0x...

# EVM Vault（使用模拟地址或部署测试版本）
VAULT_ADDRESS=0x0000000000000000000000000000000000000000  # 模拟地址
```

---

### **步骤 2：部署 Cadence 合约**

#### 2.1 更新 flow.json

编辑 `flow.json`，添加你的 Testnet 账户：

```json
{
  "accounts": {
    "testnet-account": {
      "address": "0x...",  // 你的地址
      "key": {
        "type": "hex",
        "index": 0,
        "signatureAlgorithm": "ECDSA_P256",
        "hashAlgorithm": "SHA3_256",
        "privateKey": "..."  // 你的私钥
      }
    }
  }
}
```

#### 2.2 部署合约

```bash
# 部署到 Testnet
flow project deploy --network testnet

# 记录部署的合约地址
# 更新到 .env 文件
```

---

### **步骤 3：创建测试脚本**

创建 `test-simple-schedule.js`：

```javascript
const fcl = require("@onflow/fcl");
require("dotenv").config();

// 配置 FCL
fcl.config({
    "accessNode.api": process.env.FLOW_ACCESS_NODE,
    "0xTradingScheduler": process.env.TRADING_SCHEDULER_ADDRESS,
});

async function testSchedule() {
    console.log("========================================");
    console.log("FlowForte Scheduler - Simple Test");
    console.log("========================================\n");
    
    // 设置 2 分钟后执行（快速测试）
    const executeAt = Math.floor(Date.now() / 1000) + 120;
    
    console.log("📋 Task Configuration:");
    console.log(`Execute At: ${new Date(executeAt * 1000).toISOString()}`);
    console.log(`Vault Address: ${process.env.VAULT_ADDRESS}`);
    console.log();
    
    // 构建交易
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
                log("Scheduling task...")
                
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
        console.log("📤 Submitting transaction...");
        
        const txId = await fcl.mutate({
            cadence: transaction,
            args: (arg, t) => [
                arg(process.env.VAULT_ADDRESS, t.String),
                arg("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", t.String), // FLOW
                arg("0x0000000000000000000000000000000000000001", t.String), // Mock USDC
                arg("1000000000000000000", t.UInt256), // 1 FLOW
                arg("0.05", t.UFix64), // 5% slippage
                arg(executeAt.toFixed(1), t.UFix64),
                arg("0.0", t.UFix64) // Not recurring
            ],
            proposer: fcl.currentUser,
            payer: fcl.currentUser,
            authorizations: [fcl.currentUser],
            limit: 9999
        });
        
        console.log(`\n✅ Transaction submitted!`);
        console.log(`Transaction ID: ${txId}`);
        console.log(`\n🔗 View on FlowScan:`);
        console.log(`https://testnet.flowscan.io/transaction/${txId}`);
        
        console.log("\n⏳ Waiting for transaction to be sealed...");
        const result = await fcl.tx(txId).onceSealed();
        
        console.log("\n✅ Transaction sealed!");
        console.log(`Status: ${result.status}`);
        
        // 提取 taskId
        const events = result.events.filter(e => e.type.includes("TaskScheduled"));
        if (events.length > 0) {
            console.log(`\n📊 Task ID: ${events[0].data.taskId}`);
            console.log(`Next execution: ${new Date(executeAt * 1000).toISOString()}`);
            console.log(`\n⏰ Task will execute in 2 minutes...`);
        }
        
        return txId;
        
    } catch (error) {
        console.error("\n❌ Error:", error);
        throw error;
    }
}

// 运行测试
testSchedule()
    .then(txId => {
        console.log("\n========================================");
        console.log("✅ Test completed successfully!");
        console.log("========================================");
        process.exit(0);
    })
    .catch(error => {
        console.error("\n❌ Test failed:", error.message);
        process.exit(1);
    });
```

---

### **步骤 4：运行测试**

```bash
# 安装依赖
npm install

# 运行测试脚本
node test-simple-schedule.js
```

**预期输出**：

```
========================================
FlowForte Scheduler - Simple Test
========================================

📋 Task Configuration:
Execute At: 2025-10-24T02:00:00.000Z
Vault Address: 0x0000000000000000000000000000000000000000

📤 Submitting transaction...

✅ Transaction submitted!
Transaction ID: abc123...

🔗 View on FlowScan:
https://testnet.flowscan.io/transaction/abc123...

⏳ Waiting for transaction to be sealed...

✅ Transaction sealed!
Status: 4

📊 Task ID: 1
Next execution: 2025-10-24T02:00:00.000Z

⏰ Task will execute in 2 minutes...

========================================
✅ Test completed successfully!
========================================
```

---

### **步骤 5：验证结果**

#### 5.1 在 FlowScan 查看调度交易

访问：`https://testnet.flowscan.io/transaction/{txId}`

**应该看到**：
- ✅ Transaction Status: Sealed
- ✅ Events: `TradingScheduler.TaskScheduled`
- ✅ Event Data: taskId, vaultAddress, tokenIn, tokenOut, etc.

#### 5.2 等待执行（2 分钟后）

**如果 FlowTransactionScheduler 正常工作**：
- 会自动触发执行
- 可以在 FlowScan 看到新的交易
- 事件：`TradingScheduler.TaskExecuted`

#### 5.3 查询任务状态

```bash
# 查询任务状态
node examples/query-task-status.js 1
```

---

## 🎬 演示版本（简化）

如果 FlowTransactionScheduler 在 Testnet 不可用或配置复杂，可以创建**简化演示版本**：

### **简化方案：手动触发执行**

创建 `test-manual-execution.js`：

```javascript
// 不使用 Scheduled Transactions
// 直接调用 Handler 的 executeTransaction 方法
// 模拟定时执行的效果

const transaction = `
    import TradingScheduler from ${address}
    import ScheduledSwapHandler from ${address}
    
    transaction(taskId: UInt64) {
        prepare(signer: auth(Storage) &Account) {
            // 手动触发执行
            let handler <- ScheduledSwapHandler.createHandler(...)
            handler.executeTransaction(id: taskId, data: nil)
            destroy handler
        }
    }
`;
```

**演示流程**：
1. 创建任务（显示在 FlowScan）
2. 手动触发执行（模拟定时触发）
3. 查看执行结果（显示在 FlowScan）

---

## ✅ 成功标准

### **最小可行演示（MVP）**

1. ✅ **调度交易成功**
   - 在 FlowScan 可以看到交易
   - 事件 `TaskScheduled` 被触发
   - taskId 正确生成

2. ✅ **任务信息可查询**
   - 可以通过脚本查询任务状态
   - 返回正确的任务信息

3. ✅ **执行逻辑正确**（可选）
   - 如果能集成 FlowTransactionScheduler，自动执行
   - 如果不能，手动触发也可以

### **完整演示（理想）**

1. ✅ 所有 MVP 要求
2. ✅ 自动定时执行
3. ✅ Flow Actions 集成（价格查询）
4. ✅ 跨 VM 调用 EVM（实际执行 swap）
5. ✅ 循环任务重新调度

---

## 🐛 可能遇到的问题

### **问题 1：FlowTransactionScheduler 不可用**

**解决方案**：
- 使用手动触发版本
- 或者只演示调度部分，说明执行部分的原理

### **问题 2：Flow Actions 合约地址不确定**

**解决方案**：
- 查询 Flow Forte 官方文档
- 或者暂时注释掉 Flow Actions 部分
- 使用模拟价格

### **问题 3：EVM 跨 VM 调用失败**

**解决方案**：
- 使用模拟地址，不实际调用 EVM
- 只演示编码和调用逻辑
- 在日志中显示"would call EVM with data: ..."

---

## 📝 演示脚本

### **5 分钟演示流程**

1. **介绍（1 分钟）**
   - 问题：用户需要一直在线执行策略
   - 解决方案：Scheduled Transactions

2. **展示代码（1 分钟）**
   - Workflow 配置
   - Cadence 合约关键代码

3. **运行测试（2 分钟）**
   - 执行 `node test-simple-schedule.js`
   - 展示 FlowScan 交易
   - 查询任务状态

4. **解释执行流程（1 分钟）**
   - 定时触发机制
   - Flow Actions 集成
   - 跨 VM 调用

---

## 🚀 下一步

1. **立即开始**：
   ```bash
   # 配置 Testnet 账户
   # 部署合约
   # 运行测试
   ```

2. **如果成功**：
   - 完善功能
   - 添加更多测试
   - 准备演示

3. **如果遇到问题**：
   - 使用简化版本
   - 专注于核心功能演示
   - 说明完整实现的原理

---

**记住**：黑客松重点是**展示创新和可行性**，不一定要完美运行。清晰的演示 + 完整的代码 + 详细的文档 = 成功！
