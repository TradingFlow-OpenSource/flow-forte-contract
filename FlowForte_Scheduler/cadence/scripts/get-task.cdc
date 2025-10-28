import TradingScheduler from 0xe41ad2109fdffa04

/// Query task information by task ID
access(all) fun main(taskId: UInt64): TradingScheduler.TaskInfo? {
    return TradingScheduler.getTask(taskId: taskId)
}
