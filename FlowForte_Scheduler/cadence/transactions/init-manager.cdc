import "FlowTransactionSchedulerUtils"

/// Initialize FlowTransactionSchedulerUtils.Manager
/// This only needs to be run once per account
transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        log("========================================")
        log("Initializing FlowTransactionSchedulerUtils.Manager")
        log("========================================")
        
        // Check if manager already exists
        if signer.storage.borrow<&{FlowTransactionSchedulerUtils.Manager}>(
            from: FlowTransactionSchedulerUtils.managerStoragePath
        ) != nil {
            log("⚠️  Manager already exists, skipping initialization")
            return
        }
        
        // Create and save the Manager resource
        let manager <- FlowTransactionSchedulerUtils.createManager()
        signer.storage.save(<-manager, to: FlowTransactionSchedulerUtils.managerStoragePath)
        
        log("✅ Manager created and saved")
        
        // Create a capability for the Manager
        let managerCap = signer.capabilities.storage
            .issue<&{FlowTransactionSchedulerUtils.Manager}>(FlowTransactionSchedulerUtils.managerStoragePath)
        
        signer.capabilities.publish(managerCap, at: FlowTransactionSchedulerUtils.managerPublicPath)
        
        log("✅ Manager capability published")
        log("========================================")
    }
    
    execute {
        log("Manager initialization complete")
    }
}
