import "TradingScheduler"

/// 调度定时循环交易
/// 
/// 参数：
/// - vaultAddress: EVM PersonalVault 地址
/// - tokenIn: 输入代币地址（使用 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE 表示原生 FLOW）
/// - tokenOut: 输出代币地址
/// - amountIn: 输入金额（wei 单位）
/// - slippage: 滑点容忍度（0.01 = 1%）
/// - executeAt: 首次执行时间（Unix 时间戳）
/// - frequency: 循环间隔（秒）
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
        
        log("========================================")
        log("Scheduling Recurring Swap Task")
        log("========================================")
        log("Vault Address: ".concat(vaultAddress))
        log("Token In: ".concat(tokenIn))
        log("Token Out: ".concat(tokenOut))
        log("Amount In: ".concat(amountIn.toString()))
        log("Slippage: ".concat(slippage.toString()))
        log("Execute At: ".concat(executeAt.toString()))
        log("Frequency: ".concat(frequency.toString()).concat(" seconds"))
        log("========================================")
        
        // 调度任务
        let taskId = TradingScheduler.scheduleSwap(
            vaultAddress: vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            executeAt: executeAt,
            recurring: true,
            frequency: frequency
        )
        
        log("✅ Task scheduled successfully!")
        log("Task ID: ".concat(taskId.toString()))
        log("Next execution: ".concat(executeAt.toString()))
        log("========================================")
    }
}
