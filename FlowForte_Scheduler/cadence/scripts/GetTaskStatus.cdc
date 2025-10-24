import "TradingScheduler"

/// 获取指定任务的状态
/// 
/// 参数：
/// - taskId: 任务 ID
access(all) fun main(taskId: UInt64): TradingScheduler.TaskInfo? {
    return TradingScheduler.getTask(taskId: taskId)
}
