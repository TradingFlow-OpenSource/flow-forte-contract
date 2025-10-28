import TradingScheduler from 0xe41ad2109fdffa04

/// Schedule a daily price check task
/// This transaction creates a recurring task that checks FLOW price daily
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
    prepare(signer: auth(Storage) &Account) {
        // Create a scheduled task in TradingScheduler
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
        
        log("✅ Task scheduled successfully!")
        log("Task ID: ".concat(taskId.toString()))
        log("Execute at: ".concat(executeAt.toString()))
        log("Recurring: ".concat(recurring ? "true" : "false"))
        if recurring {
            log("Frequency: ".concat(frequency.toString()).concat(" seconds"))
        }
    }
    
    execute {
        log("Task has been recorded in TradingScheduler contract")
    }
}
