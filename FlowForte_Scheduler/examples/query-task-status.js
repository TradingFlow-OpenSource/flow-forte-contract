const { SchedulerService } = require("../api/scheduler-service");
require("dotenv").config();

/**
 * 示例：查询任务状态
 */
async function main() {
    console.log("========================================");
    console.log("FlowForte Scheduler - Query Task Status");
    console.log("========================================\n");
    
    // 从命令行参数获取 taskId
    const taskId = process.argv[2];
    
    if (!taskId) {
        console.error("❌ Error: Please provide a task ID");
        console.log("\nUsage: node query-task-status.js <taskId>");
        console.log("Example: node query-task-status.js 1");
        process.exit(1);
    }
    
    // 配置
    const config = {
        accessNode: process.env.FLOW_ACCESS_NODE || "https://rest-testnet.onflow.org",
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
    
    try {
        console.log(`📊 Querying status for Task #${taskId}...\n`);
        
        // 查询任务状态
        const status = await scheduler.getTaskStatus(parseInt(taskId));
        
        if (!status) {
            console.log(`❌ Task #${taskId} not found`);
            return;
        }
        
        // 格式化输出
        console.log("========================================");
        console.log(`Task #${status.taskId} Status`);
        console.log("========================================");
        console.log(`Vault Address:    ${status.vaultAddress}`);
        console.log(`Token In:         ${status.tokenIn}`);
        console.log(`Token Out:        ${status.tokenOut}`);
        console.log(`Amount In:        ${status.amountIn}`);
        console.log(`Slippage:         ${status.slippage * 100}%`);
        console.log(`Status:           ${status.status}`);
        console.log(`Recurring:        ${status.recurring}`);
        console.log(`Frequency:        ${status.frequency} seconds (${status.frequency / 3600} hours)`);
        console.log(`Execution Count:  ${status.executionCount}`);
        
        if (status.lastExecutedAt) {
            console.log(`Last Executed:    ${new Date(status.lastExecutedAt * 1000).toISOString()}`);
        } else {
            console.log(`Last Executed:    Never`);
        }
        
        if (status.nextExecutionAt) {
            console.log(`Next Execution:   ${new Date(status.nextExecutionAt * 1000).toISOString()}`);
            
            const now = Date.now() / 1000;
            const timeUntil = status.nextExecutionAt - now;
            
            if (timeUntil > 0) {
                const hours = Math.floor(timeUntil / 3600);
                const minutes = Math.floor((timeUntil % 3600) / 60);
                const seconds = Math.floor(timeUntil % 60);
                console.log(`Time Until Next:  ${hours}h ${minutes}m ${seconds}s`);
            } else {
                console.log(`Time Until Next:  Overdue by ${Math.abs(Math.floor(timeUntil))} seconds`);
            }
        } else {
            console.log(`Next Execution:   None (task completed)`);
        }
        
        console.log("========================================\n");
        
    } catch (error) {
        console.error("\n❌ Error:", error.message);
        process.exit(1);
    }
}

// 运行示例
main().catch(console.error);
