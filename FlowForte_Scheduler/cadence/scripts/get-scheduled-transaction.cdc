import FlowTransactionScheduler from 0x8c5303eaa26202d6

/// Query scheduled transaction status
access(all) fun main(id: UInt64): FlowTransactionScheduler.Status? {
    return FlowTransactionScheduler.getStatus(id: id)
}
