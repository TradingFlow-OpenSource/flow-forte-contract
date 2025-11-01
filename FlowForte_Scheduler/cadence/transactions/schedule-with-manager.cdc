import TradingScheduler from 0xe41ad2109fdffa04
import ScheduledSwapHandler from 0xe41ad2109fdffa04
import FlowTransactionScheduler from 0x8c5303eaa26202d6
import FlowTransactionSchedulerUtils from 0x8c5303eaa26202d6
import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7

/// Complete scheduling using FlowTransactionSchedulerUtils.Manager
transaction(
    vaultAddress: String,
    tokenIn: String,
    tokenOut: String,
    amountIn: UInt256,
    slippage: UFix64,
    delaySeconds: UFix64,
    recurring: Bool,
    frequency: UFix64,
    priority: UInt8,
    executionEffort: UInt64
) {
    prepare(signer: auth(Storage, Capabilities, BorrowValue) &Account) {
        log("========================================")
        log("Scheduling Task with Manager")
        log("========================================")
        
        // Calculate future timestamp
        let future = getCurrentBlock().timestamp + delaySeconds
        
        // Step 1: Record task in TradingScheduler
        let taskId = TradingScheduler.scheduleSwap(
            vaultAddress: vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            executeAt: future,
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
        let handlerCap = signer.capabilities.storage
            .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(storagePath)
        
        log("✅ Capability created")
        
        // Step 5: Convert priority
        let pr = priority == 0
            ? FlowTransactionScheduler.Priority.High
            : priority == 1
            ? FlowTransactionScheduler.Priority.Medium
            : FlowTransactionScheduler.Priority.Low
        
        // Step 6: Get Manager
        let manager = signer.storage.borrow<auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}>(
            from: FlowTransactionSchedulerUtils.managerStoragePath
        ) ?? panic("Manager not found. Please run init-manager.cdc first")
        
        log("✅ Manager retrieved")
        
        // Step 7: Estimate fees
        let transactionData: AnyStruct? = nil
        let est = FlowTransactionScheduler.estimate(
            data: transactionData,
            timestamp: future,
            priority: pr,
            executionEffort: executionEffort
        )
        
        // Check estimation result
        assert(
            est.timestamp != nil || pr == FlowTransactionScheduler.Priority.Low,
            message: est.error ?? "estimation failed"
        )
        
        let feeAmount = est.flowFee ?? 0.0
        log("💰 Estimated fee: ".concat(feeAmount.toString()))
        
        // Step 8: Withdraw fees
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken vault")
        
        let fees <- vaultRef.withdraw(amount: feeAmount) as! @FlowToken.Vault
        
        log("✅ Fees withdrawn")
        
        // Step 9: Schedule through manager
        let transactionId = manager.schedule(
            handlerCap: handlerCap,
            data: transactionData,
            timestamp: future,
            priority: pr,
            executionEffort: executionEffort,
            fees: <-fees
        )
        
        log("✅ Scheduled transaction ID: ".concat(transactionId.toString()))
        
        log("✅ Scheduled with FlowTransactionScheduler")
        log("Task ID: ".concat(taskId.toString()))
        log("Execute at: ".concat(future.toString()))
        log("Priority: ".concat(priority.toString()))
        log("Execution Effort: ".concat(executionEffort.toString()))
        log("========================================")
    }
    
    execute {
        log("Task has been scheduled and will execute automatically!")
    }
}
