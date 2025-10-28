import "FlowTransactionScheduler"
import "DeFiActions"
import "BandOracleConnectors"
import "EVM"

/// TradingScheduler: Smart Automated Trading Scheduler
/// Combines Scheduled Transactions and Flow Actions to implement automated trading strategies
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
    
    /// Task information structure
    access(all) struct TaskInfo {
        access(all) let taskId: UInt64
        access(all) let vaultAddress: String
        access(all) let tokenIn: String
        access(all) let tokenOut: String
        access(all) let amountIn: UInt256
        access(all) let slippage: UFix64
        access(all) let recurring: Bool
        access(all) let frequency: UFix64  // Recurring interval in seconds
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
    
    /// Schedule a timed swap task
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
        
        // Create task information
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
        
        // Emit event
        emit TaskScheduled(
            taskId: taskId,
            vaultAddress: vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            executeAt: executeAt,
            recurring: recurring
        )
        
        // Note: Actual handler creation and scheduling should be done in transactions
        // This only records task information
        
        return taskId
    }
    
    /// Get task information
    access(all) fun getTask(taskId: UInt64): TaskInfo? {
        return self.tasks[taskId]
    }
    
    /// Get all tasks
    access(all) fun getAllTasks(): {UInt64: TaskInfo} {
        return self.tasks
    }
    
    /// Update task status (internal use)
    access(account) fun updateTaskStatus(taskId: UInt64, status: String) {
        if let task = self.tasks[taskId] {
            task.updateStatus(newStatus: status)
            self.tasks[taskId] = task
        }
    }
    
    /// Record task execution (internal use)
    access(account) fun recordTaskExecution(taskId: UInt64, timestamp: UFix64) {
        if let task = self.tasks[taskId] {
            task.recordExecution(timestamp: timestamp)
            self.tasks[taskId] = task
        }
    }
    
    // ========================================
    // Helper Functions
    // ========================================
    
    /// Calculate minimum output amount (based on slippage)
    access(all) fun calculateMinAmountOut(
        amountIn: UInt256,
        price: UFix64,
        slippage: UFix64
    ): UInt256 {
        // Simplified calculation: amountOut = amountIn * price * (1 - slippage)
        // Should be more precise in production
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
