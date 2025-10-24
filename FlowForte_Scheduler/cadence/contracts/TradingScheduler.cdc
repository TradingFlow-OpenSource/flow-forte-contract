import "FlowTransactionScheduler"
import "DeFiActions"
import "BandOracleConnectors"
import "EVM"

/// TradingScheduler: 智能定时交易调度器
/// 结合 Scheduled Transactions 和 Flow Actions，实现自动化交易策略
access(all) contract TradingScheduler {
    
    // ========================================
    // Storage Paths
    // ========================================
    
    access(all) let SchedulerStoragePath: StoragePath
    access(all) let SchedulerPublicPath: PublicPath
    
    // ========================================
    // State Variables
    // ========================================
    
    access(all) var nextTaskId: UInt64
    access(all) var tasks: {UInt64: TaskInfo}
    
    // ========================================
    // Structs
    // ========================================
    
    /// 任务信息
    access(all) struct TaskInfo {
        access(all) let taskId: UInt64
        access(all) let vaultAddress: String
        access(all) let tokenIn: String
        access(all) let tokenOut: String
        access(all) let amountIn: UInt256
        access(all) let slippage: UFix64
        access(all) let recurring: Bool
        access(all) let frequency: UFix64  // 循环间隔（秒）
        access(all) var status: String     // "pending", "active", "completed", "failed"
        access(all) var executionCount: UInt64
        access(all) var lastExecutedAt: UFix64?
        access(all) var nextExecutionAt: UFix64?
        
        init(
            taskId: UInt64,
            vaultAddress: String,
            tokenIn: String,
            tokenOut: String,
            amountIn: UInt256,
            slippage: UFix64,
            recurring: Bool,
            frequency: UFix64,
            nextExecutionAt: UFix64
        ) {
            self.taskId = taskId
            self.vaultAddress = vaultAddress
            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            self.amountIn = amountIn
            self.slippage = slippage
            self.recurring = recurring
            self.frequency = frequency
            self.status = "pending"
            self.executionCount = 0
            self.lastExecutedAt = nil
            self.nextExecutionAt = nextExecutionAt
        }
        
        access(all) fun updateStatus(newStatus: String) {
            self.status = newStatus
        }
        
        access(all) fun recordExecution(timestamp: UFix64) {
            self.executionCount = self.executionCount + 1
            self.lastExecutedAt = timestamp
            if self.recurring {
                self.nextExecutionAt = timestamp + self.frequency
            } else {
                self.status = "completed"
            }
        }
    }
    
    // ========================================
    // Events
    // ========================================
    
    access(all) event TaskScheduled(
        taskId: UInt64,
        vaultAddress: String,
        tokenIn: String,
        tokenOut: String,
        amountIn: UInt256,
        executeAt: UFix64,
        recurring: Bool
    )
    
    access(all) event TaskExecuted(
        taskId: UInt64,
        uniqueId: UInt64,
        success: Bool,
        amountOut: UInt256?,
        price: UFix64?,
        timestamp: UFix64
    )
    
    access(all) event TaskFailed(
        taskId: UInt64,
        reason: String,
        timestamp: UFix64
    )
    
    access(all) event TaskCancelled(
        taskId: UInt64,
        timestamp: UFix64
    )
    
    // ========================================
    // Public Functions
    // ========================================
    
    /// 调度定时交易任务
    access(all) fun scheduleSwap(
        vaultAddress: String,
        tokenIn: String,
        tokenOut: String,
        amountIn: UInt256,
        slippage: UFix64,
        executeAt: UFix64,
        recurring: Bool,
        frequency: UFix64
    ): UInt64 {
        let taskId = self.nextTaskId
        self.nextTaskId = self.nextTaskId + 1
        
        // 创建任务信息
        let taskInfo = TaskInfo(
            taskId: taskId,
            vaultAddress: vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            recurring: recurring,
            frequency: frequency,
            nextExecutionAt: executeAt
        )
        
        self.tasks[taskId] = taskInfo
        
        // 创建处理器
        let handler <- ScheduledSwapHandler.createHandler(
            taskId: taskId,
            vaultAddress: vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            recurring: recurring,
            frequency: frequency
        )
        
        // 调度执行（这里简化，实际需要调用 FlowTransactionScheduler）
        // 注意：实际实现需要根据 FlowTransactionScheduler 的 API 调整
        
        emit TaskScheduled(
            taskId: taskId,
            vaultAddress: vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            executeAt: executeAt,
            recurring: recurring
        )
        
        // 销毁 handler（实际应该保存到 scheduler）
        destroy handler
        
        return taskId
    }
    
    /// 获取任务信息
    access(all) fun getTask(taskId: UInt64): TaskInfo? {
        return self.tasks[taskId]
    }
    
    /// 获取所有任务
    access(all) fun getAllTasks(): {UInt64: TaskInfo} {
        return self.tasks
    }
    
    /// 更新任务状态（内部使用）
    access(account) fun updateTaskStatus(taskId: UInt64, status: String) {
        if let task = self.tasks[taskId] {
            task.updateStatus(newStatus: status)
            self.tasks[taskId] = task
        }
    }
    
    /// 记录任务执行（内部使用）
    access(account) fun recordTaskExecution(taskId: UInt64, timestamp: UFix64) {
        if let task = self.tasks[taskId] {
            task.recordExecution(timestamp: timestamp)
            self.tasks[taskId] = task
        }
    }
    
    // ========================================
    // Helper Functions
    // ========================================
    
    /// 计算最小输出金额（基于滑点）
    access(all) fun calculateMinAmountOut(
        amountIn: UInt256,
        price: UFix64,
        slippage: UFix64
    ): UInt256 {
        // 简化计算：amountOut = amountIn * price * (1 - slippage)
        // 实际应该更精确
        let expectedOut = UFix64(amountIn) * price
        let minOut = expectedOut * (1.0 - slippage)
        return UInt256(minOut)
    }
    
    // ========================================
    // Initialization
    // ========================================
    
    init() {
        self.SchedulerStoragePath = /storage/TradingScheduler
        self.SchedulerPublicPath = /public/TradingScheduler
        
        self.nextTaskId = 1
        self.tasks = {}
    }
}

/// ScheduledSwapHandler: 定时交易处理器
/// 实现 FlowTransactionScheduler.TransactionHandler 接口
access(all) contract ScheduledSwapHandler {
    
    // ========================================
    // Handler Resource
    // ========================================
    
    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {
        
        access(all) let taskId: UInt64
        access(all) let vaultAddress: String
        access(all) let tokenIn: String
        access(all) let tokenOut: String
        access(all) let amountIn: UInt256
        access(all) let slippage: UFix64
        access(all) let recurring: Bool
        access(all) let frequency: UFix64
        
        init(
            taskId: UInt64,
            vaultAddress: String,
            tokenIn: String,
            tokenOut: String,
            amountIn: UInt256,
            slippage: UFix64,
            recurring: Bool,
            frequency: UFix64
        ) {
            self.taskId = taskId
            self.vaultAddress = vaultAddress
            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            self.amountIn = amountIn
            self.slippage = slippage
            self.recurring = recurring
            self.frequency = frequency
        }
        
        /// 定时执行时调用
        access(FlowTransactionScheduler.Execute) 
        fun executeTransaction(id: UInt64, data: AnyStruct?) {
            log("========================================")
            log("Executing Scheduled Swap Task #".concat(self.taskId.toString()))
            log("========================================")
            
            // ========================================
            // Step 1: Flow Actions - 生成 UniqueID
            // ========================================
            let uniqueId = DeFiActions.generateUniqueId()
            log("Generated UniqueID: ".concat(uniqueId.toString()))
            
            // ========================================
            // Step 2: Flow Actions - 查询价格
            // ========================================
            var price: UFix64? = nil
            var priceQuerySuccess = false
            
            // 尝试查询价格（可选，如果失败则使用默认值）
            // 注意：需要根据实际的 BandOracleConnectors API 调整
            // price = self.queryPrice()
            
            // 简化：使用模拟价格
            price = 1.5  // 1 FLOW = 1.5 USDC
            priceQuerySuccess = true
            log("Current price: ".concat(price!.toString()))
            
            // ========================================
            // Step 3: 计算最小输出
            // ========================================
            let minAmountOut = TradingScheduler.calculateMinAmountOut(
                amountIn: self.amountIn,
                price: price!,
                slippage: self.slippage
            )
            log("Min amount out: ".concat(minAmountOut.toString()))
            
            // ========================================
            // Step 4: 跨 VM 调用 EVM Vault
            // ========================================
            let success = self.executeEVMSwap(
                minAmountOut: minAmountOut,
                uniqueId: uniqueId
            )
            
            // ========================================
            // Step 5: 记录执行结果
            // ========================================
            if success {
                log("✅ Swap executed successfully")
                TradingScheduler.recordTaskExecution(
                    taskId: self.taskId,
                    timestamp: getCurrentBlock().timestamp
                )
                
                emit TradingScheduler.TaskExecuted(
                    taskId: self.taskId,
                    uniqueId: uniqueId,
                    success: true,
                    amountOut: nil,  // 实际应该从 EVM 返回值解析
                    price: price,
                    timestamp: getCurrentBlock().timestamp
                )
                
                // ========================================
                // Step 6: 如果是循环任务，重新调度
                // ========================================
                if self.recurring {
                    self.scheduleNext()
                }
            } else {
                log("❌ Swap execution failed")
                TradingScheduler.updateTaskStatus(taskId: self.taskId, status: "failed")
                
                emit TradingScheduler.TaskFailed(
                    taskId: self.taskId,
                    reason: "EVM swap execution failed",
                    timestamp: getCurrentBlock().timestamp
                )
            }
            
            log("========================================")
        }
        
        /// 执行 EVM Swap
        access(self) fun executeEVMSwap(minAmountOut: UInt256, uniqueId: UInt64): Bool {
            log("Calling EVM Vault at: ".concat(self.vaultAddress))
            
            // ========================================
            // 编码 EVM 函数调用
            // ========================================
            let callData = self.encodeSwapCall(minAmountOut: minAmountOut)
            
            // ========================================
            // 跨 VM 调用
            // ========================================
            let evmAddress = EVM.addressFromString(self.vaultAddress)
            
            // 如果输入是原生 FLOW，需要发送 value
            let value = self.tokenIn == "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" 
                ? EVM.Balance(attoflow: UInt(self.amountIn))
                : EVM.Balance(attoflow: 0)
            
            let result = EVM.run(
                to: evmAddress,
                data: callData,
                gasLimit: 1000000,
                value: value
            )
            
            log("EVM call status: ".concat(result.status.rawValue.toString()))
            
            return result.status == EVM.Status.successful
        }
        
        /// 编码 swapExactInputSingle 调用
        /// function swapExactInputSingle(
        ///     address tokenIn,
        ///     address tokenOut,
        ///     uint256 amountIn,
        ///     uint256 amountOutMinimum,
        ///     address feeRecipient,
        ///     uint256 feeRate
        /// )
        access(self) fun encodeSwapCall(minAmountOut: UInt256): [UInt8] {
            // 函数选择器：keccak256("swapExactInputSingle(address,address,uint256,uint256,address,uint256)")[:4]
            // 实际值需要计算，这里使用占位符
            let functionSelector: [UInt8] = [0x00, 0x00, 0x00, 0x00]
            
            // TODO: 实现完整的 ABI 编码
            // 这里简化返回，实际需要正确编码所有参数
            
            log("⚠️  Warning: Using simplified EVM encoding")
            log("    In production, implement full ABI encoding")
            
            return functionSelector
        }
        
        /// 查询价格（使用 BandOracle）
        access(self) fun queryPrice(): UFix64? {
            // TODO: 实现 BandOracle 价格查询
            // let oracle = BandOracleConnectors.createPriceOracle(...)
            // return oracle.getPrice(uniqueId: uniqueId)
            
            return nil
        }
        
        /// 重新调度下一次执行
        access(self) fun scheduleNext() {
            let nextExecuteAt = getCurrentBlock().timestamp + self.frequency
            
            log("🔁 Scheduling next execution at: ".concat(nextExecuteAt.toString()))
            
            // TODO: 调用 FlowTransactionScheduler 重新调度
            // 实际实现需要创建新的 handler 并调度
        }
        
        /// 元数据视图
        access(all) view fun getViews(): [Type] {
            return [Type<StoragePath>(), Type<PublicPath>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<StoragePath>():
                    return /storage/ScheduledSwapHandler
                case Type<PublicPath>():
                    return /public/ScheduledSwapHandler
                default:
                    return nil
            }
        }
    }
    
    // ========================================
    // Factory Function
    // ========================================
    
    access(all) fun createHandler(
        taskId: UInt64,
        vaultAddress: String,
        tokenIn: String,
        tokenOut: String,
        amountIn: UInt256,
        slippage: UFix64,
        recurring: Bool,
        frequency: UFix64
    ): @Handler {
        return <- create Handler(
            taskId: taskId,
            vaultAddress: vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            recurring: recurring,
            frequency: frequency
        )
    }
}
