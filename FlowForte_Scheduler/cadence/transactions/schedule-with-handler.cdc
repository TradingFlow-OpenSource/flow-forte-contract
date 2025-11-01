import TradingScheduler from 0xe41ad2109fdffa04
import ScheduledSwapHandler from 0xe41ad2109fdffa04
import FlowTransactionScheduler from 0x8c5303eaa26202d6

/// Complete transaction: Create task + Schedule with FlowTransactionScheduler
transaction(
    vaultAddress: String,
    tokenIn: String,
    tokenOut: String,
    amountIn: UInt256,
    slippage: UFix64,
    executeAt: UFix64,
    recurring: Bool,
    frequency: UFix64
) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        log("========================================")
        log("Creating and Scheduling Task")
        log("========================================")
        
        // Step 1: Record task in TradingScheduler
        let taskId = TradingScheduler.scheduleSwap(
            vaultAddress: vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            executeAt: executeAt,
            recurring: recurring,
            frequency: frequency
        )
        
        log("✅ Task created with ID: ".concat(taskId.toString()))
        
        // Step 2: Create handler resource
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
        
        log("✅ Handler created")
        
        // Step 3: Save handler to storage
        let storagePath = StoragePath(identifier: "ScheduledSwapHandler_".concat(taskId.toString()))!
        signer.storage.save(<-handler, to: storagePath)
        
        log("✅ Handler saved to storage")
        
        // Step 4: Create capability
        let cap = signer.capabilities.storage
            .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(storagePath)
        
        log("✅ Capability created")
        
        // Step 5: Schedule with FlowTransactionScheduler
        let scheduledTransaction <- FlowTransactionScheduler.schedule(
            handlerCap: cap,
            data: nil,
            timestamp: executeAt,
            priority: FlowTransactionScheduler.Priority.medium,
            executionEffortWeight: 1000,
            extraData: nil
        )
        
        // Store the scheduled transaction
        let scheduledStoragePath = StoragePath(identifier: "ScheduledTransaction_".concat(taskId.toString()))!
        signer.storage.save(<-scheduledTransaction, to: scheduledStoragePath)
        
        log("✅ Scheduled with FlowTransactionScheduler")
        log("Task ID: ".concat(taskId.toString()))
        log("Execute at: ".concat(executeAt.toString()))
        log("========================================")
    }
    
    execute {
        log("Task has been scheduled and will execute automatically")
    }
}
