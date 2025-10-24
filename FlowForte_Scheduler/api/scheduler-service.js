const fcl = require("@onflow/fcl");
const { WorkflowAdapter } = require("./workflow-adapter");

/**
 * 调度服务
 * 提供 API 接口，将 Workflow 提交到 Flow 区块链
 */
class SchedulerService {
    
    constructor(config) {
        this.config = config;
        this.adapter = new WorkflowAdapter();
        
        // 配置 FCL
        this.configureFCL();
    }
    
    /**
     * 配置 Flow Client Library
     */
    configureFCL() {
        fcl.config({
            "accessNode.api": this.config.accessNode || "https://rest-testnet.onflow.org",
            "discovery.wallet": this.config.walletDiscovery || "https://fcl-discovery.onflow.org/testnet/authn",
            "0xTradingScheduler": this.config.contracts.TradingScheduler,
            "0xScheduledSwapHandler": this.config.contracts.ScheduledSwapHandler,
            "0xFlowTransactionScheduler": this.config.contracts.FlowTransactionScheduler,
            "0xDeFiActions": this.config.contracts.DeFiActions,
            "0xBandOracleConnectors": this.config.contracts.BandOracleConnectors,
        });
    }
    
    /**
     * 调度定时交易
     * @param {Object} workflow - Agent 生成的 workflow
     * @returns {Promise<Object>} 交易结果
     */
    async scheduleSwap(workflow) {
        try {
            console.log("📋 Parsing workflow...");
            
            // 1. 解析 workflow
            const params = this.adapter.parseScheduledSwap(workflow);
            
            console.log(this.adapter.formatParams(params));
            
            // 2. 构建 Cadence 交易
            const transaction = this.buildScheduleTransaction(params);
            
            console.log("\n📤 Submitting transaction to Flow...");
            
            // 3. 提交交易
            const txId = await fcl.mutate({
                cadence: transaction.code,
                args: transaction.args,
                proposer: fcl.currentUser,
                payer: fcl.currentUser,
                authorizations: [fcl.currentUser],
                limit: 9999
            });
            
            console.log(`Transaction ID: ${txId}`);
            console.log("⏳ Waiting for transaction to be sealed...");
            
            // 4. 等待交易确认
            const result = await fcl.tx(txId).onceSealed();
            
            console.log("✅ Transaction sealed!");
            
            // 5. 解析事件，获取 taskId
            const taskId = this.extractTaskId(result.events);
            
            return {
                success: true,
                txId: txId,
                taskId: taskId,
                executeAt: params.executeAt,
                recurring: params.recurring,
                frequency: params.frequency
            };
            
        } catch (error) {
            console.error("❌ Error scheduling swap:", error);
            throw error;
        }
    }
    
    /**
     * 构建调度交易
     * @param {Object} params - Cadence 参数
     * @returns {Object} 交易对象
     */
    buildScheduleTransaction(params) {
        const code = `
import TradingScheduler from 0xTradingScheduler

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
        `;
        
        const args = (arg, t) => [
            arg(params.vaultAddress, t.String),
            arg(params.tokenIn, t.String),
            arg(params.tokenOut, t.String),
            arg(params.amountIn, t.UInt256),
            arg(params.slippage.toFixed(2), t.UFix64),
            arg(params.executeAt.toFixed(1), t.UFix64),
            arg(params.frequency.toFixed(1), t.UFix64)
        ];
        
        return { code, args };
    }
    
    /**
     * 从事件中提取 taskId
     * @param {Array} events - 交易事件
     * @returns {number|null} taskId
     */
    extractTaskId(events) {
        for (const event of events) {
            if (event.type.includes("TaskScheduled")) {
                return event.data.taskId;
            }
        }
        return null;
    }
    
    /**
     * 查询任务状态
     * @param {number} taskId - 任务 ID
     * @returns {Promise<Object>} 任务信息
     */
    async getTaskStatus(taskId) {
        try {
            const script = `
import TradingScheduler from 0xTradingScheduler

access(all) fun main(taskId: UInt64): TradingScheduler.TaskInfo? {
    return TradingScheduler.getTask(taskId: taskId)
}
            `;
            
            const result = await fcl.query({
                cadence: script,
                args: (arg, t) => [arg(taskId.toString(), t.UInt64)]
            });
            
            return result;
            
        } catch (error) {
            console.error("Error querying task status:", error);
            throw error;
        }
    }
    
    /**
     * 查询所有任务
     * @returns {Promise<Object>} 所有任务
     */
    async getAllTasks() {
        try {
            const script = `
import TradingScheduler from 0xTradingScheduler

access(all) fun main(): {UInt64: TradingScheduler.TaskInfo} {
    return TradingScheduler.getAllTasks()
}
            `;
            
            const result = await fcl.query({
                cadence: script
            });
            
            return result;
            
        } catch (error) {
            console.error("Error querying all tasks:", error);
            throw error;
        }
    }
    
    /**
     * 查询下次执行时间
     * @param {number} taskId - 任务 ID
     * @returns {Promise<number|null>} 下次执行时间（Unix 时间戳）
     */
    async getNextExecutionTime(taskId) {
        try {
            const script = `
import TradingScheduler from 0xTradingScheduler

access(all) fun main(taskId: UInt64): UFix64? {
    if let task = TradingScheduler.getTask(taskId: taskId) {
        return task.nextExecutionAt
    }
    return nil
}
            `;
            
            const result = await fcl.query({
                cadence: script,
                args: (arg, t) => [arg(taskId.toString(), t.UInt64)]
            });
            
            return result;
            
        } catch (error) {
            console.error("Error querying next execution time:", error);
            throw error;
        }
    }
}

module.exports = { SchedulerService };
