import TradingScheduler from 0xe41ad2109fdffa04

/// Query all scheduled tasks
access(all) fun main(): {UInt64: TradingScheduler.TaskInfo} {
    return TradingScheduler.getAllTasks()
}
