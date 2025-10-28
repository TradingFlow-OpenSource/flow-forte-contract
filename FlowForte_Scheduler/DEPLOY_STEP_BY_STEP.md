# 🚀 超简单部署指南 - 手把手教学

## 📌 开始之前

你需要准备：
1. ✅ Flow CLI（已安装 ✓）
2. ⚠️ Flow 主网账户（需要创建）
3. ⚠️ 主网 FLOW 代币（需要获取）

---

## 第一步：创建或准备 Flow 主网账户

### **选项 A：如果你已经有 Flow 主网账户**

你需要知道：
- 账户地址（例如：`0x1234567890abcdef`）
- 私钥（一串很长的十六进制字符串）

**跳到第二步**

### **选项 B：如果你没有 Flow 主网账户**

#### B1. 生成新的密钥对

```bash
flow keys generate
```

**输出示例**：
```
🔴️ Store private key safely and don't share with anyone! 
Private Key      abc123def456...（很长的字符串）
Public Key       xyz789...
```

**⚠️ 重要**：把 Private Key 复制保存到安全的地方！

#### B2. 创建主网账户

有两种方式：

**方式 1：使用 Flow Wallet（推荐）**
1. 访问 https://wallet.flow.com/
2. 创建账户
3. 导出私钥

**方式 2：使用现有账户创建新账户**
```bash
# 如果你有朋友有 Flow 账户，可以帮你创建
# 或者使用交易所购买 FLOW 并转到新地址
```

#### B3. 获取 FLOW 代币

- 从交易所购买 FLOW（Binance, Kraken 等）
- 转账到你的主网地址
- 建议至少 10 FLOW（用于部署和测试）

---

## 第二步：配置项目文件

### **2.1 创建主网配置文件**

在 `FlowForte_Scheduler` 目录下，创建 `.env.mainnet` 文件：

```bash
cd /Users/beastgirl/Desktop/flow-forte-contract/FlowForte_Scheduler
touch .env.mainnet
```

### **2.2 编辑 .env.mainnet**

用文本编辑器打开 `.env.mainnet`，填入以下内容：

```env
# Flow 主网地址（你的账户地址）
FLOW_MAINNET_ADDRESS=0x你的地址

# Flow 私钥（从第一步获取）
FLOW_MAINNET_PRIVATE_KEY=你的私钥

# 合约地址（部署后会填写，现在留空）
TRADING_SCHEDULER_ADDRESS=

# 你的 PersonalVault 地址（EVM）
VAULT_ADDRESS=0x你的Vault地址

# WFLOW 地址（主网固定）
WFLOW_ADDRESS=0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e
```

**示例**（用你的实际值替换）：
```env
FLOW_MAINNET_ADDRESS=0x1234567890abcdef
FLOW_MAINNET_PRIVATE_KEY=abc123def456...
TRADING_SCHEDULER_ADDRESS=
VAULT_ADDRESS=0xYourVaultAddress
WFLOW_ADDRESS=0xd3bF53DAC106A0290B0483EcBC89d40FcC961f3e
```

### **2.3 配置 flow.json**

打开 `flow.json` 文件，找到 `"accounts"` 部分，添加：

```json
{
  "accounts": {
    "emulator-account": {
      "address": "f8d6e0586b0a20c7",
      "key": "ae1b44c0f5e8f6992ef2348898a35e50a8b0b9684000da5e1a7b50cc5b8d8c0e"
    },
    "mainnet-account": {
      "address": "0x你的地址",
      "key": {
        "type": "hex",
        "index": 0,
        "signatureAlgorithm": "ECDSA_P256",
        "hashAlgorithm": "SHA3_256",
        "privateKey": "你的私钥"
      }
    }
  },
  "deployments": {
    "mainnet": {
      "mainnet-account": [
        "TradingScheduler",
        "ScheduledSwapHandler"
      ]
    }
  }
}
```

**⚠️ 注意**：用你第一步获取的实际地址和私钥替换！

---

## 第三步：检查账户余额

在部署前，确认你的账户有足够的 FLOW：

```bash
flow accounts get 0x你的地址 --network mainnet
```

**应该看到**：
```
Address: 0x你的地址
Balance: 10.00000000 FLOW  ← 确保有余额
```

**如果余额为 0**：
- 从交易所购买 FLOW
- 转账到这个地址
- 等待确认后再继续

---

## 第四步：部署合约到主网

### **4.1 运行部署命令**

```bash
cd /Users/beastgirl/Desktop/flow-forte-contract/FlowForte_Scheduler
flow project deploy --network mainnet
```

### **4.2 预期输出**

```
Deploying 2 contracts for accounts: mainnet-account

TradingScheduler -> 0x你的地址
ScheduledSwapHandler -> 0x你的地址

✅ All contracts deployed successfully
```

### **4.3 如果出错**

**错误 1：账户余额不足**
```
Error: insufficient balance
```
→ 需要往账户转入更多 FLOW

**错误 2：找不到账户**
```
Error: account not found
```
→ 检查 flow.json 中的地址是否正确

**错误 3：私钥错误**
```
Error: invalid signature
```
→ 检查 flow.json 中的私钥是否正确

---

## 第五步：更新配置文件

部署成功后，编辑 `.env.mainnet`，填写合约地址：

```env
# 填写你的账户地址（合约部署在这个地址下）
TRADING_SCHEDULER_ADDRESS=0x你的地址
```

**注意**：合约地址就是你的账户地址！

---

## 第六步：测试部署

### **6.1 安装依赖**

```bash
npm install
```

### **6.2 运行测试**

```bash
npm run test:mainnet
```

### **6.3 预期流程**

1. 脚本会警告你这是主网操作
2. 等待 5 秒（可以按 Ctrl+C 取消）
3. 提示你连接钱包并签名
4. 提交交易到主网
5. 输出 FlowScan 链接

### **6.4 查看结果**

访问输出的链接：
```
https://flowscan.io/transaction/abc123...
```

**应该看到**：
- ✅ Status: Sealed
- ✅ Events: TaskScheduled
- ✅ Task ID: 1

---

## 🎉 完成！

如果你看到了 FlowScan 上的交易，恭喜！你已经成功：
1. ✅ 部署了 Cadence 合约到主网
2. ✅ 创建了一个定时任务
3. ✅ 在区块链浏览器上可以看到

---

## 🆘 常见问题

### **Q1: 我没有 Flow 主网账户怎么办？**

**最简单的方法**：
1. 下载 Flow Wallet App（iOS/Android）
2. 创建账户
3. 从交易所购买 FLOW 并转入
4. 导出私钥用于部署

### **Q2: 我不知道我的 PersonalVault 地址**

查看你之前部署 EVM 合约的记录，或者：

```bash
cd /Users/beastgirl/Desktop/flow-forte-contract/PersonalVault_Flow-EVM
# 查看部署脚本输出
```

如果找不到，可以先用测试地址：
```
VAULT_ADDRESS=0x0000000000000000000000000000000000000000
```

### **Q3: flow.json 配置太复杂了**

我帮你创建一个模板！看下一个文件...

### **Q4: 部署失败了怎么办？**

把错误信息发给我，我帮你分析！

---

## 📞 需要帮助？

如果任何步骤不清楚，告诉我：
1. 你卡在哪一步了
2. 看到了什么错误信息
3. 你的账户状态（有没有 FLOW 等）

我会给你更详细的指导！
