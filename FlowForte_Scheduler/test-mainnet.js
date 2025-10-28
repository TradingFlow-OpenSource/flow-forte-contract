const fcl = require("@onflow/fcl");
require("dotenv").config({ path: ".env.mainnet" });

/**
 * 主网测试脚本
 * ⚠️ 警告：这将使用真实的 FLOW！
 */

// 配置 FCL 连接主网
fcl.config({
    "accessNode.api": "https://rest-mainnet.onflow.org",
    "discovery.wallet": "https://fcl-discovery.onflow.org/authn",
    "0xTradingScheduler": process.env.TRADING_SCHEDULER_ADDRESS,
});

async function testMainnet() {
    console.log("========================================");
    console.log("FlowForte Scheduler - MAINNET Test");
    console.log("========================================\n");
    
    console.log("⚠️  WARNING: This will use REAL FLOW on MAINNET!");
    console.log("⚠️  Make sure you understand the risks!");
    console.log("\nPress Ctrl+C to cancel, or wait 5 seconds to continue...\n");
    
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // 检查配置
    if (!process.env.TRADING_SCHEDULER_ADDRESS) {
        console.error("❌ Error: TRADING_SCHEDULER_ADDRESS not set");
        console.log("\nPlease deploy to mainnet first:");
        console.log("  flow project deploy --network mainnet");
        process.exit(1);
    }
    
    if (!process.env.VAULT_ADDRESS) {
        console.error("❌ Error: VAULT_ADDRESS not set");
        console.log("\nPlease set your PersonalVault address in .env.mainnet");
        process.exit(1);
    }
    
    // 设置 5 分钟后执行（给足够时间观察）
    const executeAt = Math.floor(Date.now() / 1000) + 300;
    
    console.log("📋 Task Configuration:");
    console.log(`Execute At: ${new Date(executeAt * 1000).toISOString()}`);
    console.log(`Vault Address: ${process.env.VAULT_ADDRESS}`);
    console.log(`Token In: FLOW`);
    console.log(`Token Out: WFLOW`);
    console.log(`Amount: 0.1 FLOW (small test amount)`);
    console.log(`Slippage: 5%`);
    console.log();
    
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
                log("Scheduling Mainnet Task")
                log("========================================")
                log("Vault: ".concat(vaultAddress))
                log("Token In: ".concat(tokenIn))
                log("Token Out: ".concat(tokenOut))
                log("Amount: ".concat(amountIn.toString()))
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
        console.log("📤 Submitting transaction to Flow MAINNET...");
        console.log("⏳ Please sign the transaction in your wallet...\n");
        
        const txId = await fcl.mutate({
            cadence: transaction,
            args: (arg, t) => [
                arg(process.env.VAULT_ADDRESS, t.String),
                arg("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", t.String), // FLOW
                arg(process.env.WFLOW_ADDRESS || "0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e", t.String), // WFLOW
                arg("100000000000000000", t.UInt256), // 0.1 FLOW
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
        console.log(`\n🔗 View on FlowScan MAINNET:`);
        console.log(`https://flowscan.io/transaction/${txId}`);
        
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
            console.log(`  Time until execution: 5 minutes`);
            
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
        console.log("🔐 Authenticating with Flow Mainnet...");
        console.log("Please connect your Flow wallet.\n");
        
        const currentUser = await fcl.currentUser.snapshot();
        if (!currentUser.loggedIn) {
            await fcl.authenticate();
        }
        
        const user = await fcl.currentUser.snapshot();
        console.log(`✅ Authenticated as: ${user.addr}\n`);
        
        // 运行测试
        const { txId, result } = await testMainnet();
        
        console.log("\n========================================");
        console.log("✅ Mainnet test completed successfully!");
        console.log("========================================");
        console.log("\n📝 Summary:");
        console.log(`  - Transaction submitted and sealed on MAINNET`);
        console.log(`  - Task scheduled successfully`);
        console.log(`  - View on FlowScan: https://flowscan.io/transaction/${txId}`);
        console.log("\n🎉 Your transaction is now on Flow Mainnet!");
        console.log("\n⏰ The task will execute in 5 minutes.");
        console.log("   Check FlowScan for the execution transaction.");
        
        process.exit(0);
        
    } catch (error) {
        console.error("\n========================================");
        console.error("❌ Mainnet test failed!");
        console.error("========================================");
        console.error("Error:", error.message || error);
        process.exit(1);
    }
}

// 运行
if (require.main === module) {
    main();
}

module.exports = { testMainnet };
