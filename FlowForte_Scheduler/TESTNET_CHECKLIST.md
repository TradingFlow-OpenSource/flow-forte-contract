# ✅ 测试网部署检查清单

按顺序完成以下步骤：

## 📋 准备阶段

- [ ] **1. 创建测试网账户**
  - 方式 1: 使用 [Flow Faucet](https://testnet-faucet.onflow.org/) 创建
  - 方式 2: 使用 `flow keys generate` 生成密钥，然后在 Faucet 创建账户
  - ⚠️ **保存好私钥和地址！**

- [ ] **2. 获取测试 FLOW**
  - 访问 [Flow Testnet Faucet](https://testnet-faucet.onflow.org/)
  - 输入你的地址
  - 获取至少 **10 FLOW**

- [ ] **3. 验证账户**
  ```bash
  flow accounts get 你的地址 --network testnet
  ```
  - 确认余额 ≥ 10 FLOW
  - 记录 `Signature Algorithm` 和 `Hash Algorithm`

## ⚙️ 配置阶段

- [ ] **4. 创建 .env.testnet 文件**
  ```bash
  cp .env.testnet.example .env.testnet
  nano .env.testnet
  ```

- [ ] **5. 填写配置信息**
  ```bash
  FLOW_TESTNET_ADDRESS=0x你的地址
  FLOW_TESTNET_PRIVATE_KEY=你的私钥（不带0x）
  FLOW_TESTNET_KEY_INDEX=0
  FLOW_TESTNET_SIGNATURE_ALGORITHM=ECDSA_P256  # 根据步骤3的输出
  FLOW_TESTNET_HASH_ALGORITHM=SHA3_256         # 根据步骤3的输出
  ```

- [ ] **6. 更新 flow.json**
  - 打开 `flow.json`
  - 找到 `testnet-account` 部分
  - 更新 `address` 为你的测试网地址
  - 更新 `signatureAlgorithm` 和 `hashAlgorithm`（与步骤3一致）
  - 更新 `privateKey` 为你的私钥或使用 `$FLOW_TESTNET_PRIVATE_KEY`

- [ ] **7. 验证 flow.json 配置**
  - 确认合约地址正确：
    - FlowTransactionScheduler: `0x8c5303eaa26202d6`
    - DeFiActions: `0x4c2ff9dd03ab442f`
    - BandOracleConnectors: `0x1a9f5d18d096cd7a`
    - EVM: `0x8c5303eaa26202d6`
  - 确认部署列表包含：
    - `ScheduledSwapHandler`
    - `TradingScheduler`

## 🚀 部署阶段

- [ ] **8. 赋予脚本执行权限**
  ```bash
  chmod +x deploy-testnet.sh
  ```

- [ ] **9. 运行部署脚本**
  ```bash
  ./deploy-testnet.sh
  ```
  - 查看账户信息
  - 确认部署
  - 等待完成

- [ ] **10. 验证部署成功**
  - 查看终端输出，确认 ✅ 部署完成
  - 记录合约地址

## ✅ 验证阶段

- [ ] **11. 在 Flowscan 查看合约**
  - 访问: `https://testnet.flowscan.io/account/你的地址`
  - 确认看到 2 个合约：
    - ✅ ScheduledSwapHandler
    - ✅ TradingScheduler

- [ ] **12. 测试合约功能（可选）**
  ```bash
  cd examples
  node schedule-daily-swap.js
  node query-task-status.js
  ```

## 🎬 Demo 准备

- [ ] **13. 准备演示材料**
  - [ ] Flowscan 合约页面截图
  - [ ] 部署成功的终端输出
  - [ ] 合约代码亮点说明

- [ ] **14. 准备演示脚本**
  - [ ] 介绍项目背景（自动化交易）
  - [ ] 展示合约部署（Flowscan）
  - [ ] 说明技术亮点（Forte 特性）
  - [ ] 演示调度功能（如果时间允许）

## 📝 关键信息记录

完成后填写：

```
测试网地址: 0x____________________
合约部署时间: ____________________
Flowscan 链接: https://testnet.flowscan.io/account/____________________
```

## 🎯 完成标准

当你完成以下所有项时，就可以进行 Demo 了：

✅ 合约成功部署到测试网
✅ 在 Flowscan 上可以查看
✅ 准备好演示材料
✅ 理解核心技术点

---

**遇到问题？** 查看 `TESTNET_DEPLOYMENT.md` 中的故障排查部分。
