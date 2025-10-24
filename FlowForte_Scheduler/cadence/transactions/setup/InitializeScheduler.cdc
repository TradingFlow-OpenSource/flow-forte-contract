import "TradingScheduler"
import "ScheduledSwapHandler"

/// 初始化 TradingScheduler
/// 将调度器保存到用户账户存储中
transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        
        // 检查是否已经初始化
        if signer.storage.borrow<&AnyResource>(from: TradingScheduler.SchedulerStoragePath) != nil {
            log("TradingScheduler already initialized")
            return
        }
        
        log("Initializing TradingScheduler...")
        
        // 注意：TradingScheduler 是合约，不需要创建实例
        // 这个交易主要用于设置必要的 capabilities
        
        log("✅ TradingScheduler initialized successfully")
    }
}
