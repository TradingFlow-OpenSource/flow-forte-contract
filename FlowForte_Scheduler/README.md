# FlowForte Scheduler

**智能定时交易调度器** - 结合 Flow Forte 的 Scheduled Transactions 和 Flow Actions，为 PersonalVault 提供自动化交易能力。

---

## 🎯 项目概述

FlowForte Scheduler 是一个创新的 DeFi 自动化工具，它将：

- ✅ **Scheduled Transactions** - 定时自动执行交易，无需用户在线
- ✅ **Flow Actions** - 组合多个 DeFi 操作（价格查询、交易执行）
- ✅ **跨 VM 调用** - Cadence 调度器调用 EVM PersonalVault 合约
- ✅ **Agent 集成** - 与 AI Agent 生成的 Workflow 无缝对接

---

## 🏗️ 架构

```
Agent 生成 Workflow
    ↓
Workflow Adapter (解析)
    ↓
Scheduler Service (提交到 Flow)
    ↓
Cadence TradingScheduler (调度)
    ↓
Scheduled Transaction (定时触发)
    ↓
Flow Actions (价格查询 + 计算)
    ↓
跨 VM 调用 EVM PersonalVault
    ↓
PunchSwap V2 (执行交易)
```

---

## 📋 功能特性

### **1. 定时定额交易**
```javascript
// 每天 UTC 10:00，自动用 50 FLOW 购买 USDC
{
  "schedule": {
    "frequency": "daily",
    "time": "10:00 UTC"
  },
  "action": {
    "tokenIn": "FLOW",
    "tokenOut": "USDC",
    "amountIn": 50,
    "slippage": 0.01
  }
}
```

### **2. 灵活调度**
- 一次性交易
- 每小时/每天/每周循环
- 自定义时间间隔

### **3. Flow Actions 集成**
- 价格预言机查询（BandOracle）
- UniqueID 追踪
- 事件关联

### **4. 跨 VM 能力**
- Cadence 调度 + EVM 执行
- 完整的 ABI 编码
- Gas 管理

---

## 🚀 快速开始

### **前置要求**

1. Node.js >= 18
2. Flow CLI
3. 已部署的 PersonalVault (EVM)

### **安装**

```bash
cd FlowForte_Scheduler
npm install
```

### **配置**

复制 `.env.example` 到 `.env` 并填写配置：

```bash
cp .env.example .env
```

编辑 `.env`：

```env
# Flow 账户
FLOW_TESTNET_ADDRESS=0x...
FLOW_TESTNET_PRIVATE_KEY=...

# 合约地址
TRADING_SCHEDULER_ADDRESS=0x...

# EVM Vault
VAULT_ADDRESS=0x...
```

---

## 📖 使用指南

### **场景 1：调度每日定时交易**

```bash
# 运行示例脚本
npm run schedule:daily
```

或者使用代码：

```javascript
const { SchedulerService } = require("./api/scheduler-service");

const scheduler = new SchedulerService(config);

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

const result = await scheduler.scheduleSwap(workflow);
console.log(`Task ID: ${result.taskId}`);
```

### **场景 2：查询任务状态**

```bash
# 查询任务 #1 的状态
npm run query:status 1
```

或者使用代码：

```javascript
const status = await scheduler.getTaskStatus(1);
console.log(status);
```

---

## 🔧 API 参考

### **SchedulerService**

#### `scheduleSwap(workflow)`

调度定时交易任务。

**参数：**
```javascript
{
  vaultAddress: string,      // EVM Vault 地址
  schedule: {
    frequency: string,       // "daily", "weekly", "hourly"
    time: string            // "10:00 UTC"
  },
  action: {
    tokenIn: string,        // "FLOW" 或代币地址
    tokenOut: string,       // "USDC" 或代币地址
    amountIn: number,       // 输入金额
    slippage: number        // 滑点 (0.01 = 1%)
  }
}
```

**返回：**
```javascript
{
  success: true,
  txId: string,              // Flow 交易 ID
  taskId: number,            // 任务 ID
  executeAt: number,         // 首次执行时间
  recurring: boolean,        // 是否循环
  frequency: number          // 循环间隔（秒）
}
```

#### `getTaskStatus(taskId)`

查询任务状态。

**返回：**
```javascript
{
  taskId: number,
  vaultAddress: string,
  tokenIn: string,
  tokenOut: string,
  amountIn: string,
  slippage: number,
  status: string,            // "pending", "active", "completed", "failed"
  recurring: boolean,
  frequency: number,
  executionCount: number,
  lastExecutedAt: number,
  nextExecutionAt: number
}
```

---

## 📂 项目结构

```
FlowForte_Scheduler/
├── cadence/
│   ├── contracts/
│   │   └── TradingScheduler.cdc        # 核心调度器合约
│   ├── transactions/
│   │   ├── setup/
│   │   │   └── InitializeScheduler.cdc
│   │   └── ScheduleRecurringSwap.cdc
│   └── scripts/
│       ├── GetScheduledTasks.cdc
│       ├── GetTaskStatus.cdc
│       └── GetNextExecutionTime.cdc
│
├── lib/
│   └── evm-encoder.js                  # EVM 函数编码工具
│
├── api/
│   ├── workflow-adapter.js             # Workflow 解析器
│   └── scheduler-service.js            # 调度服务 API
│
├── examples/
│   ├── schedule-daily-swap.js          # 每日定时交易示例
│   └── query-task-status.js            # 查询任务状态示例
│
├── flow.json                           # Flow 配置
├── package.json
└── README.md
```

---

## 🎬 演示流程

### **完整演示场景**

1. **用户通过 Agent 生成 Workflow**
   ```
   "每天 10:00 自动用 50 FLOW 购买 USDC"
   ```

2. **提交到 FlowForte Scheduler**
   ```bash
   npm run schedule:daily
   ```

3. **系统输出**
   ```
   ✅ Task scheduled successfully!
   Task ID: 1
   Next execution: 2025-10-23T10:00:00.000Z
   Recurring: true
   Frequency: Every 24 hours
   ```

4. **到达执行时间（10:00 UTC）**
   - Scheduled Transaction 自动触发
   - Flow Actions 查询 FLOW/USDC 价格
   - 计算最小输出金额
   - 跨 VM 调用 EVM PersonalVault
   - 执行 swap
   - 自动调度明天 10:00 的下一次执行

5. **查询执行结果**
   ```bash
   npm run query:status 1
   ```

---

## 🔐 安全考虑

1. **权限控制**
   - 只有 ORACLE_ROLE 可以执行 swap
   - Bot 地址需要预先授权

2. **滑点保护**
   - 用户设置最大滑点
   - 价格异常时交易失败

3. **Gas 管理**
   - 设置合理的 gas limit
   - 监控执行成本

4. **私钥安全**
   - 使用环境变量
   - 不要提交到代码库

---

## 🧪 测试

### **本地测试（Flow Emulator）**

```bash
# 启动 Flow Emulator
flow emulator start

# 部署合约
flow project deploy --network emulator

# 运行测试
npm test
```

### **Testnet 测试**

```bash
# 部署到 Testnet
flow project deploy --network testnet

# 运行示例
npm run schedule:daily
```

---

## 🌟 技术亮点

### **1. Scheduled Transactions**
```cadence
// 定时自动执行，无需外部触发
access(FlowTransactionScheduler.Execute) 
fun executeTransaction(id: UInt64, data: AnyStruct?) {
    // 自动执行的代码
}
```

### **2. Flow Actions**
```cadence
// 生成 UniqueID 用于追踪
let uniqueId = DeFiActions.generateUniqueId()

// 查询价格
let price = oracle.getPrice(uniqueId: uniqueId)
```

### **3. 跨 VM 调用**
```cadence
// Cadence 调用 EVM 合约
let result = EVM.run(
    to: evmAddress,
    data: callData,
    gasLimit: 1000000,
    value: value
)
```

---

## 🤝 与主产品集成

FlowForte Scheduler 作为**增强模块**，与现有 PersonalVault 无缝集成：

```
主产品 (Agent + Workflow Generator)
    ↓
    ├─→ 立即执行 → EVM PersonalVault
    │
    └─→ 定时执行 → FlowForte Scheduler → EVM PersonalVault
```

**优势**：
- ✅ 无需修改现有 EVM 合约
- ✅ 保持向后兼容
- ✅ 可选功能，按需启用

---

## 📊 路线图

- [x] 基础定时交易
- [x] Flow Actions 集成
- [x] 跨 VM 调用
- [ ] 价格触发交易
- [ ] 复杂策略组合
- [ ] Web UI 界面
- [ ] 移动端支持

---

## 📄 许可证

MIT License

---

## 🙋 支持

如有问题，请联系：
- Discord: [Flow Discord](https://discord.gg/flow)
- GitHub Issues: [提交 Issue](https://github.com/...)

---

**FlowForte Scheduler** - 让 DeFi 自动化变得简单 🚀
