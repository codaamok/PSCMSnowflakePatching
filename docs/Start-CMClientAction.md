---
external help file: PSCMSnowflakePatching-help.xml
Module Name: PSCMSnowflakePatching
online version:
schema: 2.0.0
---

# Start-CMClientAction

## SYNOPSIS
Invoke a Configuration Manager client action on a local or remote client, see https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client.

## SYNTAX

```
Start-CMClientAction [[-ComputerName] <String>] [-ScheduleId] <TriggerSchedule> [<CommonParameters>]
```

## DESCRIPTION
Invoke a Configuration Manager client action on a local or remote client, see https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client.

This function is called by Invoke-CMSnowflakePatching.

## EXAMPLES

### EXAMPLE 1
```
Start-CMClientAction -ScheduleId ScanByUpdateSource
```

Will asynchronous start the Software Update Scan Cycle action on localhost.

## PARAMETERS

### -ComputerName
Name of the remote system you wish to invoke this action on.
If omitted, it will execute on localhost.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScheduleId
Name of a schedule ID to invoke, see https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client.

Tab complete to cycle through all the possible options, however the names are the same as per the linked doc but with spaces removed.

```yaml
Type: TriggerSchedule
Parameter Sets: (All)
Aliases:
Accepted values: HardwareInventory, SoftwareInventory, DataDiscoveryRecord, FileCollection, IDMIFCollection, ClientMachineAuthentication, MachinePolicyAssignmentsRequest, MachinePolicyEvaluation, RefreshDefaultMPTask, LocationServicesRefreshLocationsTask, LocationServicesTimeoutRefreshTask, UserPolicyAgentRequestAssignment, UserPolicyAgentEvaluateAssignment, SoftwareMeteringGeneratingUsageReport, SourceUpdateMessage, ClearingProxySettingsCache, MachinePolicyAgentCleanup, UserPolicyAgentCleanup, PolicyAgentValidateMachinePolicyAssignment, PolicyAgentValidateUserPolicyAssignment, RetryingOrRefreshingCertificatesInADonMP, PeerDPStatusReporting, PeerDPPendingPackageCheckSchedule, SUMUpdatesInstallSchedule, HardwareInventoryCollectionCycle, SoftwareInventoryCollectionCycle, DiscoveryDataCollectionCycle, FileCollectionCycle, IDMIFCollectionCycle, SoftwareMeteringUsageReportCycle, WindowsInstallerSourceListUpdateCycle, SoftwareUpdatesAssignmentsEvaluationCycle, BranchDistributionPointMaintenanceTask, SendUnsentStateMessage, StateSystemPolicyCacheCleanout, ScanByUpdateSource, UpdateStorePolicy, StateSystemPolicyBulkSendHigh, StateSystemPolicyBulkSendLow, ApplicationManagerPolicyAction, ApplicationManagerUserPolicyAction, ApplicationManagerGlobalEvaluationAction, PowerManagementStartSummarizer, EndpointDeploymentReevaluate, EndpointAMPolicyReevaluate, ExternalEventDetection

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function does not accept input from the pipeline.
## OUTPUTS

### This function does not output any object to the pipeline.
## NOTES

## RELATED LINKS
