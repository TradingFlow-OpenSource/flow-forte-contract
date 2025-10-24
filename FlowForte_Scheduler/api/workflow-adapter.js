const { ethers } = require("ethers");
const { NATIVE_TOKEN_ADDRESS } = require("../lib/evm-encoder");

/**
 * Workflow 适配器
 * 将 Agent 生成的 Workflow 转换为 Cadence 交易参数
 */
class WorkflowAdapter {
    
    /**
     * 解析定时交易 Workflow
     * @param {Object} workflow - Agent 生成的 workflow
     * @returns {Object} Cadence 交易参数
     */
    parseScheduledSwap(workflow) {
        // 验证 workflow 结构
        this.validateWorkflow(workflow);
        
        // 解析调度时间
        const executeAt = this.parseSchedule(workflow.schedule);
        
        // 解析代币地址
        const tokenIn = this.parseTokenAddress(workflow.action.tokenIn);
        const tokenOut = this.parseTokenAddress(workflow.action.tokenOut);
        
        // 解析金额（转换为 wei）
        const amountIn = this.parseAmount(workflow.action.amountIn, workflow.action.tokenIn);
        
        // 解析滑点
        const slippage = workflow.action.slippage || 0.01; // 默认 1%
        
        // 解析循环设置
        const recurring = workflow.schedule.frequency !== undefined;
        const frequency = this.parseFrequency(workflow.schedule.frequency);
        
        return {
            vaultAddress: workflow.vaultAddress,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn.toString(),
            slippage: slippage,
            executeAt: executeAt,
            recurring: recurring,
            frequency: frequency
        };
    }
    
    /**
     * 验证 workflow 结构
     */
    validateWorkflow(workflow) {
        if (!workflow.vaultAddress) {
            throw new Error("Missing vaultAddress in workflow");
        }
        
        if (!workflow.schedule) {
            throw new Error("Missing schedule in workflow");
        }
        
        if (!workflow.action) {
            throw new Error("Missing action in workflow");
        }
        
        if (!workflow.action.tokenIn || !workflow.action.tokenOut) {
            throw new Error("Missing tokenIn or tokenOut in workflow action");
        }
        
        if (!workflow.action.amountIn) {
            throw new Error("Missing amountIn in workflow action");
        }
    }
    
    /**
     * 解析调度时间
     * @param {Object} schedule - 调度配置
     * @returns {number} Unix 时间戳（秒）
     */
    parseSchedule(schedule) {
        if (schedule.executeAt) {
            // 具体时间
            const date = new Date(schedule.executeAt);
            return Math.floor(date.getTime() / 1000);
        }
        
        if (schedule.frequency) {
            // 循环任务，计算首次执行时间
            if (schedule.time) {
                // 例如："10:00 UTC"
                return this.parseTimeToday(schedule.time);
            } else {
                // 默认：当前时间 + 1 分钟
                return Math.floor(Date.now() / 1000) + 60;
            }
        }
        
        throw new Error("Invalid schedule configuration");
    }
    
    /**
     * 解析今天的特定时间
     * @param {string} timeStr - 时间字符串，例如 "10:00 UTC"
     * @returns {number} Unix 时间戳（秒）
     */
    parseTimeToday(timeStr) {
        const match = timeStr.match(/(\d{1,2}):(\d{2})\s*(UTC)?/);
        if (!match) {
            throw new Error("Invalid time format. Expected format: 'HH:MM UTC'");
        }
        
        const hours = parseInt(match[1]);
        const minutes = parseInt(match[2]);
        
        const now = new Date();
        const targetTime = new Date(Date.UTC(
            now.getUTCFullYear(),
            now.getUTCMonth(),
            now.getUTCDate(),
            hours,
            minutes,
            0
        ));
        
        // 如果目标时间已过，设置为明天
        if (targetTime.getTime() < Date.now()) {
            targetTime.setUTCDate(targetTime.getUTCDate() + 1);
        }
        
        return Math.floor(targetTime.getTime() / 1000);
    }
    
    /**
     * 解析循环频率
     * @param {string} frequency - 频率字符串："daily", "weekly", "hourly"
     * @returns {number} 间隔秒数
     */
    parseFrequency(frequency) {
        if (!frequency) return 0;
        
        const frequencies = {
            "hourly": 3600,           // 1 小时
            "daily": 86400,           // 24 小时
            "weekly": 604800,         // 7 天
            "monthly": 2592000        // 30 天
        };
        
        return frequencies[frequency.toLowerCase()] || 86400; // 默认每天
    }
    
    /**
     * 解析代币地址
     * @param {string} token - 代币符号或地址
     * @returns {string} 代币地址
     */
    parseTokenAddress(token) {
        // 如果已经是地址格式，直接返回
        if (token.startsWith("0x")) {
            return token;
        }
        
        // 代币符号映射（Flow EVM 主网）
        const tokenMap = {
            "FLOW": NATIVE_TOKEN_ADDRESS,
            "WFLOW": "0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e",
            "USDC": "0x...", // TODO: 添加实际的 USDC 地址
            "USDT": "0x...", // TODO: 添加实际的 USDT 地址
        };
        
        const address = tokenMap[token.toUpperCase()];
        if (!address) {
            throw new Error(`Unknown token symbol: ${token}`);
        }
        
        return address;
    }
    
    /**
     * 解析金额（转换为 wei）
     * @param {number|string} amount - 金额
     * @param {string} token - 代币符号
     * @returns {BigInt} wei 金额
     */
    parseAmount(amount, token) {
        // 获取代币精度（默认 18）
        const decimals = this.getTokenDecimals(token);
        
        // 转换为 wei
        return ethers.parseUnits(amount.toString(), decimals);
    }
    
    /**
     * 获取代币精度
     * @param {string} token - 代币符号或地址
     * @returns {number} 精度
     */
    getTokenDecimals(token) {
        // 大多数代币使用 18 位精度
        const decimalsMap = {
            "USDC": 6,
            "USDT": 6,
        };
        
        return decimalsMap[token.toUpperCase()] || 18;
    }
    
    /**
     * 格式化输出（用于日志）
     * @param {Object} params - Cadence 参数
     * @returns {string} 格式化的字符串
     */
    formatParams(params) {
        return `
Cadence Transaction Parameters:
================================
Vault Address: ${params.vaultAddress}
Token In:      ${params.tokenIn}
Token Out:     ${params.tokenOut}
Amount In:     ${params.amountIn}
Slippage:      ${params.slippage * 100}%
Execute At:    ${new Date(params.executeAt * 1000).toISOString()}
Recurring:     ${params.recurring}
Frequency:     ${params.frequency} seconds (${params.frequency / 3600} hours)
================================
        `.trim();
    }
}

module.exports = { WorkflowAdapter };
