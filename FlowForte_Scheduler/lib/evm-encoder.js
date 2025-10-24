const { ethers } = require("ethers");

/**
 * EVM 函数调用编码工具
 * 用于编码 PersonalVault 的 swapExactInputSingle 函数调用
 */
class EVMEncoder {
    constructor() {
        // PersonalVault swapExactInputSingle 函数签名
        this.swapFunctionABI = [
            "function swapExactInputSingle(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMinimum, address feeRecipient, uint256 feeRate) external returns (uint256)"
        ];
        
        this.iface = new ethers.Interface(this.swapFunctionABI);
    }
    
    /**
     * 编码 swapExactInputSingle 调用
     * @param {string} tokenIn - 输入代币地址
     * @param {string} tokenOut - 输出代币地址
     * @param {string|BigInt} amountIn - 输入金额
     * @param {string|BigInt} amountOutMin - 最小输出金额
     * @param {string} feeRecipient - 手续费接收地址
     * @param {string|number} feeRate - 手续费率（百万分之一）
     * @returns {string} 编码后的调用数据（hex 字符串）
     */
    encodeSwapCall(tokenIn, tokenOut, amountIn, amountOutMin, feeRecipient, feeRate) {
        const callData = this.iface.encodeFunctionData("swapExactInputSingle", [
            tokenIn,
            tokenOut,
            BigInt(amountIn),
            BigInt(amountOutMin),
            feeRecipient,
            BigInt(feeRate)
        ]);
        
        return callData;
    }
    
    /**
     * 获取函数选择器（前 4 字节）
     * @returns {string} 函数选择器
     */
    getFunctionSelector() {
        const callData = this.encodeSwapCall(
            ethers.ZeroAddress,
            ethers.ZeroAddress,
            0,
            0,
            ethers.ZeroAddress,
            0
        );
        return callData.slice(0, 10); // 0x + 8 个字符 = 4 字节
    }
    
    /**
     * 将 hex 字符串转换为字节数组（用于 Cadence）
     * @param {string} hexString - hex 字符串（带或不带 0x 前缀）
     * @returns {number[]} 字节数组
     */
    hexToByteArray(hexString) {
        // 移除 0x 前缀
        const hex = hexString.startsWith('0x') ? hexString.slice(2) : hexString;
        
        const byteArray = [];
        for (let i = 0; i < hex.length; i += 2) {
            byteArray.push(parseInt(hex.substr(i, 2), 16));
        }
        
        return byteArray;
    }
    
    /**
     * 编码并转换为 Cadence 字节数组格式
     * @param {Object} params - 参数对象
     * @returns {number[]} Cadence 字节数组
     */
    encodeForCadence(params) {
        const callData = this.encodeSwapCall(
            params.tokenIn,
            params.tokenOut,
            params.amountIn,
            params.amountOutMin,
            params.feeRecipient || ethers.ZeroAddress,
            params.feeRate || 0
        );
        
        return this.hexToByteArray(callData);
    }
    
    /**
     * 解码 swap 函数的返回值
     * @param {string} returnData - 返回数据（hex 字符串）
     * @returns {BigInt} amountOut
     */
    decodeSwapReturn(returnData) {
        const result = this.iface.decodeFunctionResult("swapExactInputSingle", returnData);
        return result[0]; // amountOut
    }
}

/**
 * 辅助函数：计算最小输出金额
 * @param {string|BigInt} amountIn - 输入金额
 * @param {number} price - 价格（输出/输入）
 * @param {number} slippage - 滑点（0.01 = 1%）
 * @returns {BigInt} 最小输出金额
 */
function calculateMinAmountOut(amountIn, price, slippage) {
    const amountInBig = BigInt(amountIn);
    const priceBig = BigInt(Math.floor(price * 1e18)); // 转换为 18 位精度
    const slippageBig = BigInt(Math.floor(slippage * 1e18));
    
    // expectedOut = amountIn * price
    const expectedOut = (amountInBig * priceBig) / BigInt(1e18);
    
    // minOut = expectedOut * (1 - slippage)
    const minOut = (expectedOut * (BigInt(1e18) - slippageBig)) / BigInt(1e18);
    
    return minOut;
}

/**
 * 常量：原生代币地址
 */
const NATIVE_TOKEN_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

module.exports = {
    EVMEncoder,
    calculateMinAmountOut,
    NATIVE_TOKEN_ADDRESS
};
