import "TradingScheduler"

/// 获取所有已调度的任务
access(all) fun main(): {UInt64: TradingScheduler.TaskInfo} {
    return TradingScheduler.getAllTasks()
}
