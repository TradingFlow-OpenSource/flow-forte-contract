const { SchedulerService } = require("../api/scheduler-service");
require("dotenv").config();

/**
 * 示例：调度每日定时交易
 * 
 * 场景：每天 UTC 10:00，自动用 50 FLOW 购买 USDC
 */
async function main() {
    console.log("========================================");
    console.log("FlowForte Scheduler - Daily Swap Example");
    console.log("========================================\n");
    
    // 配置
    const config = {
        accessNode: process.env.FLOW_ACCESS_NODE || "https://rest-testnet.onflow.org",
        walletDiscovery: "https://fcl-discovery.onflow.org/testnet/authn",
        contracts: {
            TradingScheduler: process.env.TRADING_SCHEDULER_ADDRESS,
            ScheduledSwapHandler: process.env.SCHEDULED_SWAP_HANDLER_ADDRESS,
            FlowTransactionScheduler: process.env.FLOW_TRANSACTION_SCHEDULER_ADDRESS,
            DeFiActions: process.env.DEFI_ACTIONS_ADDRESS,
            BandOracleConnectors: process.env.BAND_ORACLE_CONNECTORS_ADDRESS,
        }
    };
    
    // 创建调度服务
    const scheduler = new SchedulerService(config);
    
    // 从 Agent 生成的 Workflow
    const workflow = {
        vaultAddress: process.env.VAULT_ADDRESS,
        schedule: {
            frequency: "daily",
            time: "10:00 UTC"
        },
        action: {
            tokenIn: "FLOW",
            tokenOut: "USDC",
            amountIn: 50,
            slippage: 0.01  // 1% 滑点
        }
    };
    
    console.log("📋 Workflow from Agent:");
    console.log(JSON.stringify(workflow, null, 2));
    console.log();
    
    try {
        // 提交调度任务
        const result = await scheduler.scheduleSwap(workflow);
        
        console.log("\n========================================");
        console.log("✅ Task Scheduled Successfully!");
        console.log("========================================");
        console.log(`Task ID: ${result.taskId}`);
        console.log(`Transaction ID: ${result.txId}`);
        console.log(`Next Execution: ${new Date(result.executeAt * 1000).toISOString()}`);
        console.log(`Recurring: ${result.recurring}`);
        console.log(`Frequency: Every ${result.frequency / 3600} hours`);
        console.log("========================================\n");
        
        // 等待一会儿，然后查询任务状态
        console.log("⏳ Waiting 5 seconds before querying status...\n");
        await new Promise(resolve => setTimeout(resolve, 5000));
        
        // 查询任务状态
        console.log("📊 Querying task status...");
        const status = await scheduler.getTaskStatus(result.taskId);
        
        console.log("\nTask Status:");
        console.log(JSON.stringify(status, null, 2));
        
    } catch (error) {
        console.error("\n❌ Error:", error.message);
        process.exit(1);
    }
}

// 运行示例
main().catch(console.error);
