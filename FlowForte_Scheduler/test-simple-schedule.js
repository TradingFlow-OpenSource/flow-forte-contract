const fcl = require("@onflow/fcl");
const t = require("@onflow/types");
require("dotenv").config();

/**
 * 简单测试：创建一个定时任务
 * 目标：在 FlowScan 上看到交易和事件
 */

// 配置 FCL
fcl.config({
    "accessNode.api": process.env.FLOW_ACCESS_NODE || "https://rest-testnet.onflow.org",
    "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn",
});

async function testSchedule() {
    console.log("========================================");
    console.log("FlowForte Scheduler - Simple Test");
    console.log("========================================\n");
    
    // 检查配置
    if (!process.env.TRADING_SCHEDULER_ADDRESS) {
        console.error("❌ Error: TRADING_SCHEDULER_ADDRESS not set in .env");
        console.log("\nPlease deploy the contract first:");
        console.log("  flow project deploy --network testnet");
        console.log("\nThen update .env with the deployed address.");
        process.exit(1);
    }
    
    // 设置 2 分钟后执行（快速测试）
    const executeAt = Math.floor(Date.now() / 1000) + 120;
    
    console.log("📋 Task Configuration:");
    console.log(`Execute At: ${new Date(executeAt * 1000).toISOString()}`);
    console.log(`Vault Address: ${process.env.VAULT_ADDRESS || "0x0000000000000000000000000000000000000000"}`);
    console.log(`Token In: FLOW (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)`);
    console.log(`Token Out: Mock USDC`);
    console.log(`Amount: 1 FLOW`);
    console.log(`Slippage: 5%`);
    console.log();
    
    // 构建交易
    const transaction = `
        import TradingScheduler from ${process.env.TRADING_SCHEDULER_ADDRESS}
        
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
                log("Scheduling Swap Task")
                log("========================================")
                log("Vault: ".concat(vaultAddress))
                log("Token In: ".concat(tokenIn))
                log("Token Out: ".concat(tokenOut))
                log("Amount In: ".concat(amountIn.toString()))
                log("Execute At: ".concat(executeAt.toString()))
                log("========================================")
                
                let taskId = TradingScheduler.scheduleSwap(
                    vaultAddress: vaultAddress,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: amountIn,
                    slippage: slippage,
                    executeAt: executeAt,
                    recurring: false,
                    frequency: frequency
                )
                
                log("✅ Task scheduled successfully!")
                log("Task ID: ".concat(taskId.toString()))
                log("========================================")
            }
        }
    `;
    
    try {
        console.log("📤 Submitting transaction to Flow Testnet...");
        console.log("⏳ Please sign the transaction in your wallet...\n");
        
        const txId = await fcl.mutate({
            cadence: transaction,
            args: (arg, t) => [
                arg(process.env.VAULT_ADDRESS || "0x0000000000000000000000000000000000000000", t.String),
                arg("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", t.String), // FLOW
                arg("0x0000000000000000000000000000000000000001", t.String), // Mock USDC
                arg("1000000000000000000", t.UInt256), // 1 FLOW (in wei)
                arg("0.05", t.UFix64), // 5% slippage
                arg(executeAt.toFixed(1), t.UFix64),
                arg("0.0", t.UFix64) // Not recurring
            ],
            proposer: fcl.currentUser,
            payer: fcl.currentUser,
            authorizations: [fcl.currentUser],
            limit: 9999
        });
        
        console.log(`✅ Transaction submitted!`);
        console.log(`Transaction ID: ${txId}`);
        console.log(`\n🔗 View on FlowScan Testnet:`);
        console.log(`https://testnet.flowscan.io/transaction/${txId}`);
        
        console.log("\n⏳ Waiting for transaction to be sealed...");
        const result = await fcl.tx(txId).onceSealed();
        
        console.log("\n✅ Transaction sealed!");
        console.log(`Status: ${result.statusString || result.status}`);
        
        // 显示事件
        console.log("\n📊 Events:");
        result.events.forEach(event => {
            console.log(`  - ${event.type}`);
            if (event.type.includes("TaskScheduled")) {
                console.log(`    Task ID: ${event.data.taskId}`);
                console.log(`    Vault: ${event.data.vaultAddress}`);
                console.log(`    Execute At: ${new Date(event.data.executeAt * 1000).toISOString()}`);
            }
        });
        
        // 提取 taskId
        const scheduledEvents = result.events.filter(e => e.type.includes("TaskScheduled"));
        if (scheduledEvents.length > 0) {
            const taskId = scheduledEvents[0].data.taskId;
            console.log(`\n🎯 Task Details:`);
            console.log(`  Task ID: ${taskId}`);
            console.log(`  Next execution: ${new Date(executeAt * 1000).toISOString()}`);
            console.log(`  Time until execution: 2 minutes`);
            
            console.log(`\n💡 To query task status:`);
            console.log(`  node examples/query-task-status.js ${taskId}`);
        }
        
        return { txId, result };
        
    } catch (error) {
        console.error("\n❌ Error:", error);
        if (error.message) {
            console.error("Message:", error.message);
        }
        throw error;
    }
}

// 主函数
async function main() {
    try {
        // 认证用户
        console.log("🔐 Authenticating...");
        console.log("Please connect your Flow wallet.\n");
        
        const currentUser = await fcl.currentUser.snapshot();
        if (!currentUser.loggedIn) {
            await fcl.authenticate();
        }
        
        const user = await fcl.currentUser.snapshot();
        console.log(`✅ Authenticated as: ${user.addr}\n`);
        
        // 运行测试
        const { txId, result } = await testSchedule();
        
        console.log("\n========================================");
        console.log("✅ Test completed successfully!");
        console.log("========================================");
        console.log("\n📝 Summary:");
        console.log(`  - Transaction submitted and sealed`);
        console.log(`  - Task scheduled successfully`);
        console.log(`  - View on FlowScan: https://testnet.flowscan.io/transaction/${txId}`);
        console.log("\n🎉 You can now see your transaction on FlowScan!");
        
        process.exit(0);
        
    } catch (error) {
        console.error("\n========================================");
        console.error("❌ Test failed!");
        console.error("========================================");
        console.error("Error:", error.message || error);
        process.exit(1);
    }
}

// 运行
if (require.main === module) {
    main();
}

module.exports = { testSchedule };
