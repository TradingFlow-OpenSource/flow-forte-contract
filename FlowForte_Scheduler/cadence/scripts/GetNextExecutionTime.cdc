import "TradingScheduler"

/// 获取任务的下次执行时间
/// 
/// 参数：
/// - taskId: 任务 ID
/// 
/// 返回：
/// - 下次执行时间（Unix 时间戳），如果任务不存在或已完成则返回 nil
access(all) fun main(taskId: UInt64): UFix64? {
    if let task = TradingScheduler.getTask(taskId: taskId) {
        return task.nextExecutionAt
    }
    return nil
}
