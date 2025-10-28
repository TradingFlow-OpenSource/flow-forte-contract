/**
 * FlowForte Scheduler - 主网简单测试
 * 
 * 这个脚本会：
 * 1. 创建一个 5 分钟后执行的测试任务
 * 2. 使用小额（0.1 FLOW）进行测试
 * 3. 输出 FlowScan 链接供查看
 */

const fcl = require("@onflow/fcl");
const t = require("@onflow/types");
require("dotenv").config({ path: ".env.mainnet" });

// 配置 FCL 连接主网
fcl.config({
    "accessNode.api": "https://rest-mainnet.onflow.org",
    "discovery.wallet": "https://fcl-discovery.onflow.org/authn",
    "0xTradingScheduler": process.env.TRADING_SCHEDULER_ADDRESS || process.env.FLOW_MAINNET_ADDRESS,
});

// 配置授权
fcl.config({
    "fcl.accountProof.resolver": async () => ({
        appIdentifier: "FlowForte Scheduler",
    }),
});

async function testMainnet() {
    console.log("========================================");
    console.log("FlowForte Scheduler - 主网测试");
    console.log("========================================\n");
    
    // 检查配置
    console.log("📋 配置检查:");
    console.log(`Flow 地址: ${process.env.FLOW_MAINNET_ADDRESS}`);
    console.log(`合约地址: ${process.env.TRADING_SCHEDULER_ADDRESS || process.env.FLOW_MAINNET_ADDRESS}`);
    console.log(`Vault 地址: ${process.env.VAULT_ADDRESS || "未配置"}`);
    console.log();
    
    if (!process.env.FLOW_MAINNET_ADDRESS) {
        console.error("❌ 错误: 请在 .env.mainnet 中配置 FLOW_MAINNET_ADDRESS");
        process.exit(1);
    }
    
    if (!process.env.FLOW_MAINNET_PRIVATE_KEY) {
        console.error("❌ 错误: 请在 .env.mainnet 中配置 FLOW_MAINNET_PRIVATE_KEY");
        process.exit(1);
    }
    
    console.log("⚠️  警告: 这将在主网上使用真实的 FLOW!");
    console.log("⚠️  测试金额: 0.1 FLOW");
    console.log("⚠️  按 Ctrl+C 取消，或等待 5 秒继续...\n");
    
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // 设置 5 分钟后执行
    const executeAt = Math.floor(Date.now() / 1000) + 300;
    const executeDate = new Date(executeAt * 1000);
    
    console.log("📋 任务配置:");
    console.log(`执行时间: ${executeDate.toISOString()}`);
    console.log(`Vault 地址: ${process.env.VAULT_ADDRESS || "0x0000000000000000000000000000000000000000"}`);
    console.log(`交易对: FLOW → WFLOW`);
    console.log(`金额: 0.1 FLOW`);
    console.log(`滑点: 5%`);
    console.log();
    
    // Cadence 交易代码
    const contractAddress = process.env.TRADING_SCHEDULER_ADDRESS || process.env.FLOW_MAINNET_ADDRESS;
    
    const transaction = `
        import TradingScheduler from ${contractAddress}
        
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
                log("正在创建主网定时任务...")
                
                // 调度 swap 任务
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
                
                log("任务已创建，ID: ".concat(taskId.toString()))
            }
        }
    `;
    
    try {
        console.log("📤 正在提交到主网...");
        
        // 配置签名者
        const authz = fcl.authz;
        
        // 提交交易
        const txId = await fcl.mutate({
            cadence: transaction,
            args: (arg, t) => [
                arg(process.env.VAULT_ADDRESS || "0x0000000000000000000000000000000000000000", t.String),
                arg("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", t.String), // FLOW
                arg(process.env.WFLOW_ADDRESS || "0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e", t.String), // WFLOW
                arg("100000000000000000", t.UInt256), // 0.1 FLOW
                arg("0.05", t.UFix64), // 5% 滑点
                arg(executeAt.toFixed(1), t.UFix64),
                arg(false, t.Bool), // 不循环
                arg("0.0", t.UFix64) // 频率（不循环时为0）
            ],
            proposer: authz,
            payer: authz,
            authorizations: [authz],
            limit: 9999
        });
        
        console.log(`\n✅ 交易已提交!`);
        console.log(`交易 ID: ${txId}`);
        console.log(`\n🔗 在 FlowScan 查看（主网）:`);
        console.log(`https://flowscan.io/transaction/${txId}`);
        
        console.log("\n⏳ 等待交易确认...");
        const result = await fcl.tx(txId).onceSealed();
        
        console.log("\n✅ 交易已确认!");
        
        if (result.events && result.events.length > 0) {
            console.log(`\n📊 触发的事件:`);
            result.events.forEach(e => {
                console.log(`  - ${e.type}`);
                if (e.type.includes("TaskScheduled")) {
                    console.log(`    数据:`, e.data);
                }
            });
        }
        
        console.log("\n========================================");
        console.log("✅ 测试完成!");
        console.log("========================================");
        console.log(`\n📌 下一步:`);
        console.log(`1. 访问 FlowScan 查看交易详情`);
        console.log(`2. 等待 5 分钟后任务自动执行`);
        console.log(`3. 再次查看 FlowScan 查看执行结果`);
        console.log(`\n🔗 FlowScan 链接: https://flowscan.io/transaction/${txId}`);
        
        return txId;
        
    } catch (error) {
        console.error("\n❌ 错误:", error);
        
        if (error.message) {
            console.error("\n错误详情:", error.message);
        }
        
        console.log("\n🔍 故障排查:");
        console.log("1. 检查账户余额是否充足");
        console.log("2. 检查合约是否已部署");
        console.log("3. 检查 .env.mainnet 配置是否正确");
        console.log("4. 运行: flow accounts get", process.env.FLOW_MAINNET_ADDRESS, "--network mainnet");
        
        throw error;
    }
}

// 运行测试
testMainnet()
    .then(txId => {
        console.log("\n✅ 主网测试成功!");
        process.exit(0);
    })
    .catch(error => {
        console.error("\n❌ 测试失败:", error.message);
        process.exit(1);
    });
