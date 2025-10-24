# FlowForte Scheduler - 实现说明

## 📝 当前状态

本项目已完成**核心架构和代码框架**，包括：

✅ **已完成**：
- Cadence 合约框架（TradingScheduler + ScheduledSwapHandler）
- Workflow 适配器（解析 Agent 生成的 Workflow）
- 调度服务 API（提交和查询任务）
- EVM 编码工具（编码 swapExactInputSingle 调用）
- 示例脚本（调度和查询）
- 完整文档

⚠️ **需要完善**：
1. EVM 函数调用的完整 ABI 编码
2. FlowTransactionScheduler 的实际集成
3. BandOracle 价格查询的实现
4. 测试和调试

---

## 🔧 关键实现要点

### **1. EVM 函数编码（需要完善）**

当前 `TradingScheduler.cdc` 中的 `encodeSwapCall` 是简化版本：

```cadence
// 当前实现（简化）
access(self) fun encodeSwapCall(minAmountOut: UInt256): [UInt8] {
    let functionSelector: [UInt8] = [0x00, 0x00, 0x00, 0x00]
    // TODO: 实现完整的 ABI 编码
    return functionSelector
}
```

**需要实现**：

```cadence
access(self) fun encodeSwapCall(minAmountOut: UInt256): [UInt8] {
    // 1. 函数选择器
    // keccak256("swapExactInputSingle(address,address,uint256,uint256,address,uint256)")[:4]
    let functionSelector: [UInt8] = [0xab, 0xcd, 0xef, 0x12]  // 需要实际计算
    
    // 2. 编码参数（每个参数 32 字节）
    let params: [UInt8] = []
    
    // tokenIn (address, 32 bytes)
    params = params.concat(self.encodeAddress(self.tokenIn))
    
    // tokenOut (address, 32 bytes)
    params = params.concat(self.encodeAddress(self.tokenOut))
    
    // amountIn (uint256, 32 bytes)
    params = params.concat(self.encodeUInt256(self.amountIn))
    
    // amountOutMinimum (uint256, 32 bytes)
    params = params.concat(self.encodeUInt256(minAmountOut))
    
    // feeRecipient (address, 32 bytes)
    params = params.concat(self.encodeAddress("0x0000000000000000000000000000000000000000"))
    
    // feeRate (uint256, 32 bytes)
    params = params.concat(self.encodeUInt256(0))
    
    return functionSelector.concat(params)
}

// 辅助函数：编码地址
access(self) fun encodeAddress(address: String): [UInt8] {
    // 实现地址编码（20 字节地址 + 12 字节填充）
}

// 辅助函数：编码 UInt256
access(self) fun encodeUInt256(value: UInt256): [UInt8] {
    // 实现 UInt256 编码（32 字节大端序）
}
```

**或者使用 JavaScript 预编码**：

在 `lib/evm-encoder.js` 中已经实现了完整的 ABI 编码，可以：
1. 在 JavaScript 中编码调用数据
2. 通过交易参数传递给 Cadence
3. Cadence 直接使用编码好的数据

---

### **2. FlowTransactionScheduler 集成**

当前代码中调度逻辑是简化的：

```cadence
// 当前实现（简化）
access(all) fun scheduleSwap(...) {
    let handler <- ScheduledSwapHandler.createHandler(...)
    
    // TODO: 实际调用 FlowTransactionScheduler
    // let taskId = FlowTransactionScheduler.schedule(...)
    
    destroy handler
}
```

**需要实现**：

根据 FlowTransactionScheduler 的实际 API（参考 Flow 文档）：

```cadence
import "FlowTransactionScheduler"

access(all) fun scheduleSwap(...) {
    // 1. 创建 handler
    let handler <- ScheduledSwapHandler.createHandler(...)
    
    // 2. 保存到存储
    let storagePath = /storage/ScheduledSwapHandler_${taskId}
    signer.storage.save(<-handler, to: storagePath)
    
    // 3. 创建 capability
    let cap = signer.capabilities.storage
        .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(storagePath)
    
    // 4. 调度执行
    FlowTransactionScheduler.schedule(
        handler: cap,
        executeAt: executeAt,
        priority: 1,
        executionEffort: 10000,
        data: nil
    )
}
```

---

### **3. BandOracle 价格查询**

当前使用模拟价格：

```cadence
// 当前实现（模拟）
price = 1.5  // 1 FLOW = 1.5 USDC
```

**需要实现**：

```cadence
import "BandOracleConnectors"

access(self) fun queryPrice(): UFix64? {
    // 创建 Oracle Action
    let oracle = BandOracleConnectors.createPriceOracle(
        baseSymbol: "FLOW",
        quoteSymbol: "USD"
    )
    
    // 查询价格
    let uniqueId = DeFiActions.generateUniqueId()
    let priceData = oracle.getPrice(uniqueId: uniqueId)
    
    return priceData.price
}
```

---

### **4. 循环任务重新调度**

当前 `scheduleNext()` 是空实现：

```cadence
access(self) fun scheduleNext() {
    let nextExecuteAt = getCurrentBlock().timestamp + self.frequency
    log("🔁 Scheduling next execution at: ".concat(nextExecuteAt.toString()))
    // TODO: 实际重新调度
}
```

**需要实现**：

```cadence
access(self) fun scheduleNext() {
    let nextExecuteAt = getCurrentBlock().timestamp + self.frequency
    
    // 创建新的 handler
    let newHandler <- ScheduledSwapHandler.createHandler(
        taskId: self.taskId,
        vaultAddress: self.vaultAddress,
        tokenIn: self.tokenIn,
        tokenOut: self.tokenOut,
        amountIn: self.amountIn,
        slippage: self.slippage,
        recurring: self.recurring,
        frequency: self.frequency
    )
    
    // 调度新任务
    TradingScheduler.scheduleSwap(...)
    
    destroy newHandler
}
```

---

## 🧪 测试计划

### **阶段 1：单元测试**

1. **EVM 编码测试**
   ```javascript
   // 测试 ABI 编码是否正确
   const encoder = new EVMEncoder();
   const callData = encoder.encodeSwapCall(...);
   // 验证与 ethers.js 编码结果一致
   ```

2. **Workflow 解析测试**
   ```javascript
   // 测试 Workflow 解析
   const adapter = new WorkflowAdapter();
   const params = adapter.parseScheduledSwap(workflow);
   // 验证参数正确
   ```

### **阶段 2：集成测试（Emulator）**

1. **部署合约**
   ```bash
   flow emulator start
   flow project deploy --network emulator
   ```

2. **调度任务**
   ```bash
   # 设置 30 秒后执行（快速测试）
   node examples/schedule-daily-swap.js
   ```

3. **验证执行**
   ```bash
   # 等待 30 秒
   # 查询任务状态
   node examples/query-task-status.js 1
   ```

### **阶段 3：Testnet 测试**

1. **部署到 Testnet**
   ```bash
   flow project deploy --network testnet
   ```

2. **真实场景测试**
   - 使用真实的 EVM Vault 地址
   - 使用真实的代币地址
   - 小额测试（避免损失）

---

## 📋 部署清单

### **前置准备**

- [ ] Flow Testnet 账户（有 FLOW 余额）
- [ ] 已部署的 PersonalVault (EVM)
- [ ] Bot 地址有 ORACLE_ROLE 权限
- [ ] 测试代币（FLOW, USDC 等）

### **部署步骤**

1. **配置环境变量**
   ```bash
   cp .env.example .env
   # 编辑 .env，填写所有必要配置
   ```

2. **安装依赖**
   ```bash
   npm install
   ```

3. **部署 Cadence 合约**
   ```bash
   flow project deploy --network testnet
   ```

4. **记录合约地址**
   ```bash
   # 将部署的合约地址更新到 .env
   TRADING_SCHEDULER_ADDRESS=0x...
   ```

5. **测试调度**
   ```bash
   npm run schedule:daily
   ```

---

## 🐛 已知问题和限制

### **1. EVM 编码**
- 当前使用简化的编码，需要实现完整的 ABI 编码
- 建议：使用 JavaScript 预编码，通过参数传递

### **2. FlowTransactionScheduler API**
- 需要根据实际的 FlowTransactionScheduler 合约 API 调整
- Forte 更新可能导致 API 变化

### **3. Gas 估算**
- 跨 VM 调用的 gas limit 需要根据实际测试调整
- 当前设置为 1000000，可能不够或过多

### **4. 错误处理**
- 需要更完善的错误处理和重试机制
- 交易失败时的回滚策略

---

## 🚀 优化建议

### **性能优化**

1. **批量调度**
   - 支持一次调度多个任务
   - 减少交易次数

2. **Gas 优化**
   - 优化 Cadence 代码，减少计算
   - 使用更高效的数据结构

### **功能增强**

1. **条件触发**
   - 除了定时，支持价格触发
   - 支持更复杂的条件组合

2. **策略模板**
   - 预定义常用策略
   - 用户一键启用

3. **监控和通知**
   - 任务执行通知
   - 失败告警

---

## 📚 参考资料

- [Flow Forte 文档](https://developers.flow.com/blockchain-development-tutorials/forte)
- [Scheduled Transactions](https://developers.flow.com/blockchain-development-tutorials/forte/scheduled-transactions)
- [Flow Actions](https://developers.flow.com/blockchain-development-tutorials/forte/flow-actions)
- [Flow EVM](https://developers.flow.com/build/evm)
- [FCL 文档](https://developers.flow.com/build/tools/fcl-js)

---

## 🤝 贡献指南

欢迎贡献！请：

1. Fork 项目
2. 创建功能分支
3. 提交 Pull Request
4. 确保代码通过测试

---

**最后更新**: 2025-10-22
