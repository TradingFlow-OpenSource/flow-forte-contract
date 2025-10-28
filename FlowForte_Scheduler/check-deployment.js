/**
 * FlowForte Scheduler - 部署检查工具
 * 
 * 在部署前运行此脚本，检查所有配置是否正确
 */

const fs = require('fs');
const path = require('path');

console.log("========================================");
console.log("FlowForte Scheduler - 部署检查");
console.log("========================================\n");

let hasErrors = false;
let hasWarnings = false;

// 检查 1: .env.mainnet 文件
console.log("📋 检查 1: 环境配置文件");
const envPath = path.join(__dirname, '.env.mainnet');
if (fs.existsSync(envPath)) {
    console.log("✅ .env.mainnet 文件存在");
    
    // 加载环境变量
    require('dotenv').config({ path: '.env.mainnet' });
    
    // 检查必需的环境变量
    const requiredVars = [
        'FLOW_MAINNET_ADDRESS',
        'FLOW_MAINNET_PRIVATE_KEY'
    ];
    
    const optionalVars = [
        'TRADING_SCHEDULER_ADDRESS',
        'VAULT_ADDRESS',
        'WFLOW_ADDRESS',
        'FACTORY_ADDRESS'
    ];
    
    console.log("\n  必需配置:");
    requiredVars.forEach(varName => {
        if (process.env[varName]) {
            console.log(`  ✅ ${varName}: ${process.env[varName].substring(0, 10)}...`);
        } else {
            console.log(`  ❌ ${varName}: 未配置`);
            hasErrors = true;
        }
    });
    
    console.log("\n  可选配置:");
    optionalVars.forEach(varName => {
        if (process.env[varName]) {
            console.log(`  ✅ ${varName}: ${process.env[varName]}`);
        } else {
            console.log(`  ⚠️  ${varName}: 未配置（部署后需要填写）`);
            if (varName === 'VAULT_ADDRESS') {
                hasWarnings = true;
            }
        }
    });
    
} else {
    console.log("❌ .env.mainnet 文件不存在");
    console.log("   请运行: cp .env.mainnet.example .env.mainnet");
    hasErrors = true;
}

// 检查 2: flow.json 配置
console.log("\n\n📋 检查 2: Flow 配置文件");
const flowJsonPath = path.join(__dirname, 'flow.json');
if (fs.existsSync(flowJsonPath)) {
    console.log("✅ flow.json 文件存在");
    
    try {
        const flowJson = JSON.parse(fs.readFileSync(flowJsonPath, 'utf8'));
        
        // 检查主网账户配置
        if (flowJson.accounts && flowJson.accounts['mainnet-account']) {
            console.log("✅ mainnet-account 已配置");
            
            const mainnetAccount = flowJson.accounts['mainnet-account'];
            if (mainnetAccount.address) {
                console.log(`  地址: ${mainnetAccount.address}`);
            }
            if (mainnetAccount.key) {
                console.log(`  密钥类型: ${mainnetAccount.key.type || 'hex'}`);
                console.log(`  签名算法: ${mainnetAccount.key.signatureAlgorithm || 'ECDSA_P256'}`);
            }
        } else {
            console.log("❌ mainnet-account 未配置");
            hasErrors = true;
        }
        
        // 检查部署配置
        if (flowJson.deployments && flowJson.deployments.mainnet) {
            console.log("✅ 主网部署配置存在");
            const contracts = flowJson.deployments.mainnet['mainnet-account'] || [];
            console.log(`  待部署合约: ${contracts.join(', ')}`);
        } else {
            console.log("⚠️  主网部署配置不存在");
            hasWarnings = true;
        }
        
    } catch (error) {
        console.log("❌ flow.json 解析失败:", error.message);
        hasErrors = true;
    }
} else {
    console.log("❌ flow.json 文件不存在");
    hasErrors = true;
}

// 检查 3: Cadence 合约文件
console.log("\n\n📋 检查 3: Cadence 合约");
const contractPath = path.join(__dirname, 'cadence/contracts/TradingScheduler.cdc');
if (fs.existsSync(contractPath)) {
    console.log("✅ TradingScheduler.cdc 存在");
    
    const contractContent = fs.readFileSync(contractPath, 'utf8');
    
    // 检查关键导入
    const requiredImports = [
        'FlowTransactionScheduler',
        'DeFiActions',
        'BandOracleConnectors',
        'EVM'
    ];
    
    console.log("\n  合约导入检查:");
    requiredImports.forEach(importName => {
        if (contractContent.includes(`import "${importName}"`)) {
            console.log(`  ✅ ${importName}`);
        } else {
            console.log(`  ⚠️  ${importName} (可能使用不同的导入方式)`);
        }
    });
    
} else {
    console.log("❌ TradingScheduler.cdc 不存在");
    hasErrors = true;
}

// 检查 4: Node.js 依赖
console.log("\n\n📋 检查 4: Node.js 依赖");
const packageJsonPath = path.join(__dirname, 'package.json');
const nodeModulesPath = path.join(__dirname, 'node_modules');

if (fs.existsSync(packageJsonPath)) {
    console.log("✅ package.json 存在");
    
    if (fs.existsSync(nodeModulesPath)) {
        console.log("✅ node_modules 存在");
        
        // 检查关键依赖
        const requiredDeps = ['@onflow/fcl', '@onflow/types', 'dotenv', 'ethers'];
        console.log("\n  关键依赖:");
        requiredDeps.forEach(dep => {
            const depPath = path.join(nodeModulesPath, dep);
            if (fs.existsSync(depPath)) {
                console.log(`  ✅ ${dep}`);
            } else {
                console.log(`  ❌ ${dep} 未安装`);
                hasErrors = true;
            }
        });
    } else {
        console.log("❌ node_modules 不存在");
        console.log("   请运行: npm install");
        hasErrors = true;
    }
} else {
    console.log("❌ package.json 不存在");
    hasErrors = true;
}

// 检查 5: Flow CLI
console.log("\n\n📋 检查 5: Flow CLI");
const { execSync } = require('child_process');
try {
    const flowVersion = execSync('flow version', { encoding: 'utf8' });
    console.log("✅ Flow CLI 已安装");
    console.log(`  版本: ${flowVersion.trim()}`);
} catch (error) {
    console.log("❌ Flow CLI 未安装或不在 PATH 中");
    console.log("   请访问: https://developers.flow.com/tools/flow-cli/install");
    hasErrors = true;
}

// 总结
console.log("\n\n========================================");
console.log("检查总结");
console.log("========================================\n");

if (hasErrors) {
    console.log("❌ 发现错误，请修复后再部署\n");
    console.log("📝 修复步骤:");
    console.log("1. 创建 .env.mainnet 文件并填写配置");
    console.log("2. 检查 flow.json 中的账户配置");
    console.log("3. 运行 npm install 安装依赖");
    console.log("4. 安装 Flow CLI");
    process.exit(1);
} else if (hasWarnings) {
    console.log("⚠️  有警告，但可以继续部署\n");
    console.log("📝 建议:");
    console.log("1. 部署后记得更新 TRADING_SCHEDULER_ADDRESS");
    console.log("2. 如果有 PersonalVault，填写 VAULT_ADDRESS");
    process.exit(0);
} else {
    console.log("✅ 所有检查通过，可以开始部署!\n");
    console.log("📝 下一步:");
    console.log("1. 检查账户余额: flow accounts get <地址> --network mainnet");
    console.log("2. 部署合约: flow project deploy --network mainnet");
    console.log("3. 更新 .env.mainnet 中的 TRADING_SCHEDULER_ADDRESS");
    console.log("4. 运行测试: npm run test:mainnet");
    process.exit(0);
}
