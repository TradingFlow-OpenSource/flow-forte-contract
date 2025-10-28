# FlowForte Scheduler - 快速入门指南

## 🎯 5 分钟快速上手

### **步骤 1：安装依赖**

```bash
cd FlowForte_Scheduler
npm install
```

### **步骤 2：配置环境**

```bash
cp .env.example .env
```

编辑 `.env`，填写必要配置：

```env
# 最少需要配置这些
VAULT_ADDRESS=0x...                    # 你的 EVM Vault 地址
FLOW_TESTNET_ADDRESS=0x...             # Flow 账户地址
FLOW_TESTNET_PRIVATE_KEY=...          # Flow 私钥
```

### **步骤 3：运行示例**

```bash
# 调度每日定时交易
npm run schedule:daily
```

---

## 📖 详细步骤

### **1. 准备 Flow 账户**

如果还没有 Flow Testnet 账户：

```bash
# 安装 Flow CLI
brew install flow-cli

# 创建账户
flow keys generate

# 到 Testnet Faucet 领取测试币
# https://testnet-faucet.onflow.org/
```

### **2. 部署 Cadence 合约**

```bash
# 配置 flow.json
# 更新 testnet-account 的地址和私钥

# 部署合约
flow project deploy --network testnet

# 记录部署的合约地址
# 更新到 .env
```

### **3. 验证 EVM Vault**

确保你的 PersonalVault：
- 已部署到 Flow EVM
- Bot 地址有 ORACLE_ROLE 权限
- 有足够的代币余额

```bash
# 在 PersonalVault_Flow-EVM 目录
npx hardhat run scripts/createVault.js --network flow
```

### **4. 测试调度**

创建测试脚本 `test-schedule.js`：

```javascript
const { SchedulerService } = require("./api/scheduler-service");
require("dotenv").config();

async function test() {
    const config = {
        accessNode: "https://rest-testnet.onflow.org",
        contracts: {
            TradingScheduler: process.env.TRADING_SCHEDULER_ADDRESS,
            // ... 其他配置
        }
    };
    
    const scheduler = new SchedulerService(config);
    
    // 设置 30 秒后执行（快速测试）
    const executeAt = Math.floor(Date.now() / 1000) + 30;
    
    const workflow = {
        vaultAddress: process.env.VAULT_ADDRESS,
        schedule: {
            executeAt: new Date(executeAt * 1000).toISOString()
        },
        action: {
            tokenIn: "FLOW",
            tokenOut: "USDC",
            amountIn: 1,  // 小额测试
            slippage: 0.05  // 5% 滑点（测试环境）
        }
    };
    
    console.log("Scheduling task...");
    const result = await scheduler.scheduleSwap(workflow);
    console.log("Task ID:", result.taskId);
    console.log("Will execute in 30 seconds...");
    
    // 等待执行
    await new Promise(resolve => setTimeout(resolve, 35000));
    
    // 查询结果
    const status = await scheduler.getTaskStatus(result.taskId);
    console.log("Task status:", status);
}

test().catch(console.error);
```

运行测试：

```bash
node test-schedule.js
```

---

## 🎬 黑客松演示脚本

### **演示准备**

1. **准备演示环境**
   ```bash
   # 确保所有合约已部署
   # 确保 Vault 有足够余额
   # 准备好演示账户
   ```

2. **准备演示数据**
   ```javascript
   // 创建一个清晰的 Workflow
   const workflow = {
       vaultAddress: "0x...",
       schedule: {
           frequency: "daily",
           time: "10:00 UTC"
       },
       action: {
           tokenIn: "FLOW",
           tokenOut: "USDC",
           amountIn: 50,
           slippage: 0.01
       }
   };
   ```

### **演示流程（5 分钟）**

#### **第 1 分钟：介绍问题**

"传统 DeFi 自动化的痛点：
- 用户需要一直在线
- 需要运行自己的 Bot
- 中心化的自动化服务不可信

Flow Forte 的解决方案：
- Scheduled Transactions：链上定时执行
- Flow Actions：标准化的 DeFi 组合
- 跨 VM：结合 Cadence 和 EVM 的优势"

#### **第 2 分钟：展示 Workflow**

"我们的 AI Agent 生成了这个策略：
每天 10:00 自动用 50 FLOW 购买 USDC"

```bash
# 展示 workflow.json
cat workflow.json
```

#### **第 3 分钟：提交调度**

"一键提交到 FlowForte Scheduler："

```bash
npm run schedule:daily
```

"系统输出：
- ✅ 任务已调度
- Task ID: 1
- 下次执行：明天 10:00 UTC"

#### **第 4 分钟：演示执行**

"为了演示，我们设置 30 秒后执行："

```bash
# 运行快速测试脚本
node test-schedule.js
```

"等待 30 秒...

执行流程：
1. ⏰ Scheduled Transaction 触发
2. 📊 Flow Actions 查询价格
3. 🧮 计算最小输出
4. 🌉 跨 VM 调用 EVM Vault
5. ✅ 交易完成"

#### **第 5 分钟：查询结果**

"查询任务状态："

```bash
npm run query:status 1
```

"结果显示：
- Status: completed
- Execution Count: 1
- Last Executed: 刚才
- Next Execution: 明天 10:00（如果是循环任务）"

---

## 🔧 常见问题

### **Q: 合约部署失败？**

A: 检查：
- Flow 账户余额是否足够
- flow.json 配置是否正确
- 网络连接是否正常

### **Q: 任务没有执行？**

A: 检查：
- executeAt 时间是否正确（未来时间）
- FlowTransactionScheduler 是否正常工作
- Bot 是否有足够的 gas

### **Q: EVM 调用失败？**

A: 检查：
- Vault 地址是否正确
- Bot 是否有 ORACLE_ROLE
- 代币余额是否足够
- ABI 编码是否正确

---

## 📚 下一步

- 阅读 [README.md](./README.md) 了解完整功能
- 查看 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md) 了解技术细节
- 探索 `examples/` 目录的更多示例
- 加入 [Flow Discord](https://discord.gg/flow) 获取支持

---

**祝黑客松顺利！🚀**
