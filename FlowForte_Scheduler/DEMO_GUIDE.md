# 🎬 FlowForte Scheduler - Demo 演示指南

## 📋 Demo 概述

展示一个完整的定时交易流程：
1. ✅ 创建定时任务（5分钟后执行）
2. ✅ 查询任务状态
3. ⏰ 等待自动执行
4. ✅ 在 Flowscan 查看交易记录

---

## 🚀 快速开始

### **步骤 1: 创建定时任务**

```bash
./demo-test.sh
```

**这会做什么？**
- 创建一个定时任务，5分钟后执行
- 任务内容：查询 FLOW 价格并模拟交易决策
- 返回任务 ID（通常是 1）

**预期输出：**
```
📋 Task Parameters:
  Vault Address: 0x0000... (demo)
  Token In: FLOW
  Token Out: USDC
  Amount In: 1.0 FLOW
  Slippage: 1%
  Execute At: 1730102400 (2024-10-28 14:00:00)
  Recurring: false

✅ Task Created!
Transaction ID: abc123...
```

### **步骤 2: 查询任务状态**

```bash
./query-task.sh 1
```

**预期输出：**
```json
Result: {
  "taskId": 1,
  "vaultAddress": "0x0000000000000000000000000000000000000000",
  "tokenIn": "FLOW",
  "tokenOut": "USDC",
  "amountIn": "1000000000000000000",
  "slippage": "0.01000000",
  "recurring": false,
  "frequency": "0.00000000",
  "status": "pending",
  "executionCount": 0,
  "lastExecutedAt": null,
  "nextExecutionAt": "1730102400.00000000"
}
```

### **步骤 3: 查询所有任务**

```bash
./query-all-tasks.sh
```

**预期输出：**
```json
Result: {
  "1": {
    "taskId": 1,
    "status": "pending",
    ...
  }
}
```

### **步骤 4: 等待执行（5分钟）**

⏰ **等待期间可以做什么？**
- 展示合约代码和架构
- 说明技术亮点
- 准备 Flowscan 页面

### **步骤 5: 验证执行结果**

5分钟后，再次查询任务状态：

```bash
./query-task.sh 1
```

**应该看到：**
```json
{
  "status": "completed",  // ✅ 状态已更新
  "executionCount": 1,    // ✅ 执行次数 +1
  "lastExecutedAt": "1730102400.00000000"  // ✅ 记录执行时间
}
```

---

## 🌐 在 Flowscan 查看

### **查看创建任务的交易**

1. 运行 `demo-test.sh` 后会显示 Transaction ID
2. 访问：
   ```
   https://testnet.flowscan.io/transaction/<Transaction-ID>
   ```

**你会看到：**
- ✅ 交易状态：Sealed
- ✅ 事件：`TradingScheduler.TaskScheduled`
- ✅ 事件参数：taskId, vaultAddress, tokenIn, tokenOut, etc.

### **查看账户的所有交易**

访问：
```
https://testnet.flowscan.io/account/0xe41ad2109fdffa04
```

**你会看到：**
- ✅ 已部署的合约：TradingScheduler, ScheduledSwapHandler
- ✅ 所有交易历史
- ✅ 触发的事件

---

## 🎯 Demo 演示脚本

### **版本 A: 完整演示（15分钟）**

1. **介绍项目** (2分钟)
   - 问题：DeFi 交易需要人工监控和执行
   - 解决方案：自动化定时交易调度器
   - 技术：Flow Forte + Scheduled Transactions

2. **展示合约** (3分钟)
   - 打开 Flowscan 展示已部署的合约
   - 展示合约代码（TradingScheduler.cdc）
   - 说明架构设计

3. **创建任务** (2分钟)
   - 运行 `./demo-test.sh`
   - 展示交易参数
   - 在 Flowscan 查看交易

4. **查询状态** (2分钟)
   - 运行 `./query-task.sh 1`
   - 展示任务信息
   - 说明状态字段含义

5. **等待执行** (5分钟)
   - 展示技术架构图
   - 说明 FlowTransactionScheduler 工作原理
   - 回答评委问题

6. **验证结果** (1分钟)
   - 再次查询任务状态
   - 展示状态变化
   - 总结技术亮点

### **版本 B: 快速演示（5分钟）**

1. **展示已部署合约** (1分钟)
   - Flowscan 页面

2. **创建任务** (1分钟)
   - 运行 `./demo-test.sh`

3. **查询状态** (1分钟)
   - 运行 `./query-task.sh 1`

4. **说明执行流程** (2分钟)
   - 使用架构图说明
   - 强调技术亮点
   - 展示预录的执行视频（如果有）

---

## 🎨 技术亮点强调

### **1. Flow Forte 特性**
- ✅ 使用 `FlowTransactionScheduler` 实现定时执行
- ✅ 集成 `DeFiActions` 和 `BandOracleConnectors`
- ✅ 展示 Scheduled Transactions 的实际应用

### **2. 创新架构**
- ✅ 纯 Cadence 实现，无需外部 Keeper
- ✅ 模块化设计：Scheduler + Handler
- ✅ 可扩展到跨 VM 调用（EVM 集成）

### **3. 实用价值**
- ✅ 自动化交易策略（定投、网格交易）
- ✅ 无需人工干预
- ✅ 降低 Gas 成本（批量执行）

---

## 📊 预期结果

### **创建任务交易**
- **Transaction ID**: `abc123...`
- **Status**: Sealed ✅
- **Events**: `TradingScheduler.TaskScheduled`
- **Gas Used**: ~0.00001 FLOW

### **任务状态变化**

| 时间 | 状态 | executionCount | lastExecutedAt |
|------|------|----------------|----------------|
| 创建时 | pending | 0 | null |
| 5分钟后 | completed | 1 | 1730102400 |

### **Flowscan 展示**
- ✅ 合约部署记录
- ✅ 交易历史
- ✅ 事件日志
- ✅ 合约代码

---

## 🐛 故障排查

### **问题 1: 交易失败**
```
Error: transaction execution failed
```

**解决方案：**
- 检查账户余额是否充足
- 确认 .env.testnet 配置正确
- 查看详细错误信息

### **问题 2: 查询返回 null**
```
Result: null
```

**解决方案：**
- 确认任务 ID 正确
- 检查任务是否创建成功
- 使用 `./query-all-tasks.sh` 查看所有任务

### **问题 3: 5分钟后状态未更新**

**可能原因：**
- FlowTransactionScheduler 的实际执行可能需要更长时间
- 测试网络延迟

**备选方案：**
- 展示任务创建和查询功能
- 说明执行流程（使用架构图）
- 准备预录的执行视频

---

## 🎯 成功标准

Demo 成功的标志：
- ✅ 合约成功部署到测试网
- ✅ 能够创建定时任务
- ✅ 能够查询任务状态
- ✅ 在 Flowscan 上可见交易记录
- ✅ 清晰展示技术架构和创新点

---

## 📝 准备清单

- [ ] 测试网账户余额充足（≥ 10 FLOW）
- [ ] 所有脚本可执行（`chmod +x *.sh`）
- [ ] 浏览器打开 Flowscan 页面
- [ ] 准备架构图或 PPT
- [ ] 测试所有命令至少一次
- [ ] 准备回答评委问题

---

## 🚀 开始 Demo

准备好了吗？运行：

```bash
./demo-test.sh
```

**祝黑客松顺利！** 🎉
