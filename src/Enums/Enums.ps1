enum EvaluationState {
    None
    Available
    Submitted
    Detecting
    PreDownload  
    Downloading  
    WaitInstall  
    Installing   
    PendingSoftReboot
    PendingHardReboot
    WaitReboot   
    Verifying
    InstallComplete  
    Error
    WaitServiceWindow
    WaitUserLogon
    WaitUserLogoff   
    WaitJobUserLogon 
    WaitUserReconnect
    PendingUserLogoff
    PendingUpdate
    WaitingRetry 
    WaitPresModeOff  
    WaitForOrchestration
}

enum TriggerSchedule {
    HardwareInventory = 1
    SoftwareInventory
    DataDiscoveryRecord
    FileCollection = 10
    IDMIFCollection
    ClientMachineAuthentication
    MachinePolicyAssignmentsRequest	= 21
    MachinePolicyEvaluation
    RefreshDefaultMPTask
    LocationServicesRefreshLocationsTask
    LocationServicesTimeoutRefreshTask
    UserPolicyAgentRequestAssignment
    UserPolicyAgentEvaluateAssignment
    SoftwareMeteringGeneratingUsageReport = 31
    SourceUpdateMessage
    ClearingProxySettingsCache = 37
    MachinePolicyAgentCleanup = 40
    UserPolicyAgentCleanup
    PolicyAgentValidateMachinePolicyAssignment
    PolicyAgentValidateUserPolicyAssignment
    RetryingOrRefreshingCertificatesInADonMP = 51
    PeerDPStatusReporting = 61
    PeerDPPendingPackageCheckSchedule
    SUMUpdatesInstallSchedule
    HardwareInventoryCollectionCycle = 101
    SoftwareInventoryCollectionCycle
    DiscoveryDataCollectionCycle
    FileCollectionCycle
    IDMIFCollectionCycle
    SoftwareMeteringUsageReportCycle
    WindowsInstallerSourceListUpdateCycle
    SoftwareUpdatesAssignmentsEvaluationCycle
    BranchDistributionPointMaintenanceTask
    SendUnsentStateMessage = 111
    StateSystemPolicyCacheCleanout
    ScanByUpdateSource
    UpdateStorePolicy
    StateSystemPolicyBulkSendHigh
    StateSystemPolicyBulkSendLow
    ApplicationManagerPolicyAction = 121
    ApplicationManagerUserPolicyAction
    ApplicationManagerGlobalEvaluationAction
    PowerManagementStartSummarizer = 131
    EndpointDeploymentReevaluate = 221
    EndpointAMPolicyReevaluate
    ExternalEventDetection
}