function Invoke-CMSnowflakePatching {
    <#
    .SYNOPSIS
        Invoke software update installation for a ConfigMgr client, an array of clients, or by ConfigMgr collection.
    .DESCRIPTION
        Invoke software update installation for a ConfigMgr client, an array of clients, or by ConfigMgr collection.

        The function will attempt to install all available updates on a target system. By default it will not reboot or 
        retry failed installations.

        You can pass a single, or array of, computer names, or you can specify a ConfigMgr collection ID. Alternatively,
        you can use the ChooseCollection switch which will present a searchable list of all ConfigMgr device collections
        to choose from in an Out-GridView window.

        If ComputerName, ChooseCollection, and CollectionId parameters are not used, the ChooseCollection is the default
        parameter set.

        If multiple ConfigMgr clients are in scope, all will be processed and monitored asyncronously using jobs. The
        function will not immediately return. It will wait until all jobs are no longer running.

        Progress will be written as host output to the console, and log file in the %temp% directory.

        An output pscustomobject will be returned at the end if either the ComputerName or CollectionId parameters
        were used. If the ChooseCollection switch was used, no output object is returned (progress will still be written
        to the host). 
        
        There will be an output object per target client. It will contain properties such as result, updates installed, 
        whether a pending reboot is required, and how many times a system rebooted and how
        many times software update installations were retried.

        A system can be allowed to reboot and retry multiple times with the AllowReboot or Retry parameter (or both).

        It is recommended you read my blog post to understand the various ways in how you can use this function: 
        https://adamcook.io/p/Patch-Snowflakes-with-ConfigMgr-and-PowerShell
    .PARAMETER ComputerName
        Name of the remote systems you wish to invoke software update installations on.
        This parameter cannot be used with the ChooseCollection or CollectionId parameters.
    .PARAMETER ChooseCollection
        A PowerShell Out-GridView window will appear, prompting you to choose a ConfigMgr device collection. 
        All members of this collection will be patched.
        This parameter cannot be used with the ComputerName or CollectionId parameters.
    .PARAMETER CollectionId
        A ConfigMgr collection ID of whose members you intend to patch.
        All members of this collection will be patched.
        This parameter cannot be used with the ComputerName or ChooseCollection parameters.
    .PARAMETER AllowReboot
        If an update returns a soft or hard pending reboot, specifying this switch will allow the system to be rebooted
        after all updates have finished installing. By default, the function will not reboot the system(s). 
        More often than not, reboots are required in order to finalise software update installation. Using this switch
        and allowing the system(s) to reboot if required ensures a complete patch cycle.
    .PARAMETER Retry
        Specify the number of retries you would like to script to make when a software update install failure is detected.
        In other words, if software updates fail to install, and you specify 2 for the Retry parameter, the script will
        retry installation twice.
    .EXAMPLE
        Invoke-CMSnowflakePatching -ComputerName 'ServerA', 'ServerB' -AllowReboot

        Will invoke software update installation on 'ServerA' and 'ServerB' and reboot the systems if any updates return
        a soft or hard pending reboot.
    .EXAMPLE 
        Invoke-CMSnowflakePatching -ChooseCollection -AllowReboot

        An Out-GridView dialogue will be preented to the user to choose a ConfigMgr device collection. All members of
        the collection will be targted for software update installation. They will be rebooted if any updates
        return a soft or hard pending reboot.
    .EXAMPLE
        Invoke-CMSnowflakePatching -CollectionId P0100016 -AllowReboot

        Will invoke software update installation on all members of the ConfigMgr device collection ID P0100016. They
        will be rebooted if any updates return a soft or hard pending reboot.
    .INPUTS
        This function does not accept input from the pipeline.
    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByChoosingConfigMgrCollection')]
    [OutputType([PSCustomObject], ParameterSetName=('ByComputerName','ByConfigMgrCollectionId'))]
    param(
        [Parameter(Mandatory, 
            ValueFromPipeline, 
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'ByComputerName')]
        [String[]]$ComputerName,

        [Parameter(ParameterSetName = 'ByChoosingConfigMgrCollection')]
        [Switch]$ChooseCollection,

        [Parameter(Mandatory,
            ParameterSetName = 'ByConfigMgrCollectionId')]
        [String]$CollectionId,

        [Parameter()]
        [Switch]$AllowReboot,

        [Parameter()]
        [Int]$Retry = 1
    )

    #region Define PSDefaultParameterValues, other variables, and enums
    $JobId = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $StartTime = Get-Date

    # NewLoopAction function is the primary looping function in this script
    # The below variables configure the function's timeout values where appropriate
    $RebootTimeoutMins = 120 # How long to wait for a host to become responsive again after reboot
    $SoftwareUpdateScanCycleTimeoutMins = 15 # How long to wait for a successful execution of the Software Update Scan Cycle after update install/reboot
    $InvokeSoftwareUpdateInstallTimeoutMins = 5 # How long to wait for updates to begin installing after invoking them to begin installing
    $InstallUpdatesTimeoutMins = 720 # How long to wait for installing software updates on a host

    $PSDefaultParameterValues = @{
        'WriteCMLogEntry:Bias'                 = (Get-CimInstance -ClassName Win32_TimeZone | Select-Object -ExpandProperty Bias)
        'WriteCMLogEntry:Folder'               = $env:temp
        'WriteCMLogEntry:FileName'             = 'Invoke-CMSnowflakePatching_{0}.log' -f $JobId
        'WriteCMLogEntry:MaxLogFileSize'       = 5MB
        'WriteCMLogEntry:MaxNumOfRotatedLogs'  = 0
        'WriteCMLogEntry:ErrorAction'          = $ErrorActionPreference
        'WriteScreenInfo:ScriptStart'          = $StartTime
    }
    #endregion

    'Starting' | WriteScreenInfo -PassThru | WriteCMLogEntry -Component 'Initialisation'

    WriteCMLogEntry -Value ('ParameterSetName: {0}' -f $PSCmdlet.ParameterSetName) -Component 'Initialisation'
    WriteCMLogEntry -Value ('ForceReboot: {0}' -f $AllowReboot.IsPresent) -Component 'Initialisation'
    WriteCMLogEntry -Value ('Retries: {0}' -f $Retry) -Component 'Initialisation'

    if ($PSCmdlet.ParameterSetName -ne 'ByComputerName') {
        $PSDrive = (Get-PSDrive -PSProvider CMSite)[0]
        $CMDrive = '{0}:\' -f $PSDrive.Name
        Push-Location $CMDrive

        switch ($PSCmdlet.ParameterSetName) {
            'ByChoosingConfigMgrCollection' {
                WriteCMLogEntry -Value 'Getting all device collections' -Component 'Initialisation'
                try {
                    $DeviceCollections = Get-CMCollection -CollectionType 'Device' -ErrorAction 'Stop'
                    WriteCMLogEntry -Value 'Success' -Component 'Initialisation'
                }
                catch {
                    'Failed to get device collections' | 
                        WriteScreenInfo -Type 'Error' -PassThru | 
                        WriteCMLogEntry -Severity 3 -Component 'Initialisation'
                    WriteCMLogEntry -Value $_.Exception.Message -Severity 3 -Component 'Initialisation'
                    Pop-Location 
                    $PSCmdlet.ThrowTerminatingError($_)
                }

                'Prompting user to choose a collection' | WriteScreenInfo -Indent 1 -PassThru | WriteCMLogEntry -Component 'Initialisation'
                $Collection = $DeviceCollections | 
                    Select-Object Name, CollectionID, MemberCount, Comment | 
                    Out-GridView -Title 'Choose a Configuration Manager collection' -PassThru

                if (-not $Collection) {
                    'User did not choose a collection, quitting' | 
                        WriteScreenInfo -Indent 1 -Type 'Warning' -PassThru | 
                        WriteCMLogEntry -Severity 2 -Component 'Initialisation'
                    Pop-Location 
                    return
                }
                else {
                    'User chose collection {0}' -f $Collection.CollectionID | 
                        WriteScreenInfo -Indent 1 -PassThru | 
                        WriteCMLogEntry -Component 'Initialisation'
                }
            }
            'ByConfigMgrCollectionId' {
                'Getting collection {0}' -f $CollectionId | WriteScreenInfo -PassThru | WriteCMLogEntry -Component 'Initialisation'
                try {
                    $Collection = Get-CMCollection -Id $CollectionId -CollectionType 'Device' -ErrorAction 'Stop'
                    if ($null -eq $Collection) {
                        $Exception = [System.ArgumentException]::new('Did not find a device collection with ID {0}' -f $CollectionId)
                        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                            $Exception,
                            $null,
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $ComputerName
                        )
                        $PSCmdlet.ThrowTerminatingError($ErrorRecord)                    
                    }
                    else {
                        'Success' | WriteScreenInfo -Indent 1 -PassThru | WriteCMLogEntry -Component 'Initialisation'
                    }
                }
                catch {
                    'Failed to get collection {0}' -f $CollectionId | 
                        WriteScreenInfo -Type 'Error' -PassThru | 
                        WriteCMLogEntry -Severity 3 -Component 'Initialisation'
                    WriteCMLogEntry -Value $_.Exception.Message -Severity 3 -Component 'Initialisation'
                    Pop-Location 
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
        }
        
        'Getting collection members' | WriteScreenInfo -PassThru | WriteCMLogEntry -Component 'Initialisation'

        try {
            $CollectionMembers = Get-CMCollectionMember -CollectionId $Collection.CollectionID -ErrorAction 'Stop'
        }
        catch {
            'Failed to get collection members' -f $CollectionId | 
                WriteScreenInfo -Type 'Error' -PassThru | 
                WriteCMLogEntry -Severity 3 -Component 'Initialisation'
            WriteCMLogEntry -Value $_.Exception.Message -Severity 3 -Component 'Initialisation'
            Pop-Location 
            $PSCmdlet.ThrowTerminatingError($_)
        }

        'Number of members: {0}' -f @($CollectionMembers).Count | WriteScreenInfo -Indent 1 -PassThru | WriteCMLogEntry -Component 'Initialisation'
        
        Pop-Location    
    }
    else {
        $CollectionMembers = foreach ($Computer in $ComputerName) {
            [PSCustomObject]@{
                Name = $Computer
            }
        }
    }

    $Jobs = foreach ($Member in $CollectionMembers) {
        $StartJobSplat = @{
            Name                 = $Member.Name
            InitializationScript = { Import-Module 'PSCMSnowflakePatching' -ErrorAction 'Stop' }
            ArgumentList         = @(
                $Member.Name, 
                $AllowReboot.IsPresent, 
                $Retry, 
                $InvokeSoftwareUpdateInstallTimeoutMins, 
                $InstallUpdatesTimeoutMins
            )
            ErrorAction          = 'Stop'
            ScriptBlock          = {
                param (
                    [String]$ComputerName,
                    [Bool]$AllowReboot,
                    [Int]$Retry,
                    [Int]$InvokeSoftwareUpdateInstallTimeoutMins,
                    [Int]$InstallUpdatesTimeoutMins
                )

                $Module = Get-Module 'PSCMSnowflakePatching'

                $Updates = Get-CMSoftwareUpdates -ComputerName $ComputerName -Filter 'ComplianceState = 0' -ErrorAction 'Stop'
                
                [CimInstance[]]$AvailableUpdates         = $Updates | Where-Object { 0,1 -contains $_.EvaluationState             }
                [CimInstance[]]$FailedUpdates            = $Updates | Where-Object { $_.EvaluationState -eq 13                    }
                #[CimInstance[]]$UpdatesInprogress        = $Updates | Where-Object { 2..7 + 11 -contains $_.EvaluationState       }
                #[CimInstance[]]$PendingSoftRebootUpdates = $Updates | Where-Object { 8, 10 -contains $_.EvaluationState           }
                #[CimInstance[]]$PendingHardRebootUpdates = $Updates | Where-Object { $_.EvaluationState -eq 9                     }
                #[CimInstance[]]$InstallComplete          = $Updates | Where-Object { $_.EvaluationState -eq 12                    }
                #[CimInstance[]]$OtherUpdates             = $Updates | Where-Object { $_.EvaluationState -notmatch '^[0-9][1-3]?$' }
        
                if ($AvailableUpdates.Count -gt 0 -Or $FailedUpdates.Count -gt 0) {
                    $UpdatesToInstall = $Updates | Where-Object { 0,1,13 -contains $_.EvaluationState }

                    $Iterations = if (-not $AllowReboot -Or $Retry -lt 1) { 1 } else { $Retry }
                    $RebootCounter   = 0
                    $AttemptsCounter = 0

                    & $Module NewLoopAction -Iterations $Iterations -LoopDelay 0 -ScriptBlock {
                        $AttemptsCounter++

                        $InvokeCMSoftwareUpdateInstallSplat = @{
                            ComputerName                           = $ComputerName
                            Update                                 = $UpdatesToInstall
                            InvokeSoftwareUpdateInstallTimeoutMins = $InvokeSoftwareUpdateInstallTimeoutMins
                            InstallUpdatesTimeoutMins              = $InstallUpdatesTimeoutMins
                            ErrorAction                            = 'Stop'
                        }
                        $Result = Invoke-CMSoftwareUpdateInstall @InvokeCMSoftwareUpdateInstallSplat
                        
                        if ($AllowReboot -And $Result.EvaluationState -match '^8$|^9$|^10$') {
                            $RebootCounter++

                            Restart-Computer -ComputerName $ComputerName -Force -ErrorAction 'Stop'

                            & $Module NewLoopAction -LoopTimeout $RebootTimeoutMins -LoopTimeoutType 'Minutes' -LoopDelay 15 -LoopDelayType 'Seconds' -ScriptBlock {
                                # Wait for SMS Agent Host to startup and for relevant ConfigMgr WMI classes to become available
                            } -ExitCondition {
                                try {
                                    $null = Get-CMSoftwareUpdates -ComputerName $ComputerName -ErrorAction 'Stop'
                                    return $true
                                }
                                catch {}
                            } -IfTimeoutScript {
                                $Exception = [System.TimeoutException]::new('Timeout while waiting for {0} to reboot' -f $ComputerName)
                                $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                                    $Exception,
                                    $null,
                                    [System.Management.Automation.ErrorCategory]::OperationTimeout,
                                    $ComputerName
                                )
                                $PSCmdlet.ThrowTerminatingError($ErrorRecord)                    
                            }
                            
                        }
                    } -ExitCondition {
                        & $Module NewLoopAction -LoopTimeout $SoftwareUpdateScanCycleTimeoutMins -LoopTimeoutType 'Minutes' -LoopDelay 1 -LoopDelayType 'Seconds' -ScriptBlock { } -ExitCondition {
                            try {
                                Start-CMClientAction -ComputerName $ComputerName -ScheduleId 'ScanByUpdateSource' -ErrorAction 'Stop'
                                Start-Sleep -Seconds 180
                                Start-CMClientAction -ComputerName $ComputerName -ScheduleId 'ScanByUpdateSource' -ErrorAction 'Stop'
                                Start-Sleep -Seconds 180
                                return $true
                            }
                            catch {
                                if ($_.FullyQualifiedErrorId -match '0x80070005|0x80041001') {
                                    # If ccmexec service hasn't started yet, or is still starting, access denied is thrown
                                    return $false
                                }
                                else {
                                    $PSCmdlet.ThrowTerminatingError($_)
                                }
                            }
                        } -IfTimeoutScript {
                            $Exception = [System.TimeoutException]::new('Timeout while trying to invoke Software Update Scan Cycle for {0}' -f $ComputerName)
                            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                                $Exception,
                                $null,
                                [System.Management.Automation.ErrorCategory]::OperationTimeout,
                                $ComputerName
                            )
                            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
                        }

                        $Filter = 'ArticleID = "{0}"' -f [String]::Join('" OR ArticleID = "', $UpdatesToInstall.ArticleID)
                        
                        $LatestUpdates = Get-CMSoftwareUpdates -ComputerName $ComputerName -Filter $Filter -ErrorAction 'Stop'

                        switch ($AllowReboot) {
                            $true {
                                # If updates are successfully installed, they will no longer appear in WMI
                                if ($LatestUpdates.Count -eq 0) { return $true }
                            }
                            $false {
                                # Don't want anything other than pending hard/soft reboot, or installed
                                # Ideally, the update(s) should no longer be present in WMI if they're installed w/o reboot required, or be in a state of pending reboot which is OK
                                $NotWant = '^{0}$' -f ([String]::Join('$|^', 0..7+10+11+13..23))
                                if (@($LatestUpdates.EvaluationState -match $NotWant).Count -eq 0) { 
                                    return $true 
                                } else { 
                                    # If this occurs, the iterations on the loop will exceed and the IfTimeoutScript script block will be invoked, thus reporting back one or more updates failed
                                    return $false 
                                }
                            }
                        }
                        
                    } -IfTimeoutScript {
                        [PSCustomObject]@{
                            ComputerName    = $ComputerName
                            Result          = 'Failure'
                            Updates         = $LatestUpdates | Select-Object Name, ArticleID, EvaluationState, ErrorCode
                            IsPendingReboot = $LatestUpdates.EvaluationState -match '^8$|^9$' -as [bool]
                            NumberOfReboots = $RebootCounter
                            NumberOfRetries = $AttemptsCounter - 1
                        }
                    } -IfSucceedScript {
                        [PSCustomObject]@{
                            ComputerName    = $ComputerName
                            Result          = 'Success'
                            Updates         = $UpdatesToInstall | Select-Object Name, ArticleID, EvaluationState
                            IsPendingReboot = $LatestUpdates.EvaluationState -match '^8$|^9$' -as [bool]
                            NumberOfReboots = $RebootCounter
                            NumberOfRetries = $AttemptsCounter - 1
                        }
                    }
                }
                else {
                    [PSCustomObject]@{
                        ComputerName    = $ComputerName
                        Result          = 'n/a'
                        Updates         = $null
                        IsPendingReboot = $false
                        NumberOfReboots = 0
                        NumberOfRetries = 0
                    }
                }
            }
        }

        'Creating an async job to patch{0} {1}' -f $(if ($AllowReboot) { ' and reboot'} else { }), $Member.Name | WriteScreenInfo -PassThru | WriteCMLogEntry -Component 'Jobs'

        try {
            Start-Job @StartJobSplat
            'Success' | WriteScreenInfo -Indent 1 -PassThru | WriteCMLogEntry -Component 'Jobs'
        } catch {
            'Failed to create job' | WriteScreenInfo -Indent 1 -Type 'Error' -PassThru| WriteCMLogEntry -Component 'Jobs'
            WriteCMLogEntry -Value $_.Exception.Message -Severity 3 -Component 'Jobs'
            Write-Error $_ -ErrorAction $ErrorActionPreference
        }
    }

    if ($Jobs -And ($Jobs -is [Object[]] -Or $Jobs -is [System.Management.Automation.Job])) {
        'Waiting for updates to finish installing{0}for {1} hosts' -f $(if ($AllowReboot) { ' and rebooting '} else { ' ' }), $Jobs.Count |
            WriteScreenInfo -PassThru |
            WriteCMLogEntry -Component 'Patching'

        $CompletedJobs = [System.Collections.Generic.List[String]]@()
        $FailedJobs    = [System.Collections.Generic.List[String]]@()
        
        $Result = do {
            foreach ($_Job in $Jobs) {
                $Change = $false
                switch ($true) {
                    ($_Job.State -eq 'Completed' -And $CompletedJobs -notcontains $_Job.Name) {
                        $CompletedJobs.Add($_Job.Name)
                        $Data = $_Job | Receive-Job -Keep
                        $Data

                        switch ($Data.Result) {
                            'n/a' {
                                '{0} did not install any updates as none were available' -f $_Job.Name |
                                    WriteScreenInfo -PassThru | 
                                    WriteCMLogEntry -Component 'Patching'
                            }
                            'Success' {
                                '{0} rebooted {1} times and successfully installed:' -f $_Job.Name, $Data.NumberOfReboots |
                                    WriteScreenInfo -PassThru |
                                    WriteCMLogEntry -Component 'Patching'

                                foreach ($item in $Data.Updates) {
                                    $item.Name |
                                        WriteScreenInfo -Indent 1 -PassThru |
                                        WriteCMLogEntry -Component 'Patching'
                                }
                            }
                            'Failure' { 
                                '{0} failed to install one or more updates:' -f $_Job.Name |
                                WriteScreenInfo -Type 'Error' -PassThru |
                                WriteCMLogEntry -Component 'Patching' -Severity 3

                                foreach ($item in $Data.Updates) {
                                    'Update "{0}" finished with evaluation state {1} and exit code {2}' -f $item.Name, [EvaluationState]$item.EvaluationState, $item.ErrorCode |
                                        WriteScreenInfo -Indent 1 -PassThru |
                                        WriteCMLogEntry -Component 'Patching'
                                }
                            }
                        }

                        if ($Data.IsPendingReboot) {
                            '{0} has one or more updates pending a reboot' -f $_Job.Name |
                                WriteScreenInfo -Type 'Warning' -PassThru |
                                WriteCMLogEntry -Component 'Patching' -Severity 2
                        }

                        $Change = $true
                    }
                    ($_Job.State -eq 'Failed' -And $FailedJobs -notcontains $_Job.Name) {
                        $FailedJobs.Add($_Job.Name)
                        '{0} (job ID {1}) failed because: {2}' -f $_Job.Name, $_Job.Id, $_Job.ChildJobs[0].JobStateInfo.Reason |
                            WriteScreenInfo -Indent 1 -Type 'Error' -PassThru |
                            WriteCMLogEntry -Severity 3 -Component 'Patching'
                        $Change = $true
                    }
                    $Change {
                        $RunningJobs = @($Jobs | Where-Object { $_.State -eq 'Running' }).Count
                        if ($RunningJobs -ge 1) {
                            'Waiting for {0} hosts' -f $RunningJobs |
                                WriteScreenInfo -PassThru |
                                WriteCMLogEntry -Component 'Patching'
                        }
                    }
                }
            }
        } until (
            $Jobs.Where{$_.State -eq 'Running'}.Count -eq 0 -And 
            (
                ($CompletedJobs.Count -eq $Jobs.Where{$_.State -eq 'Completed'}.Count -And $CompletedJobs.Count -gt 0) -Or
                ($FailedJobs.Count -eq $Jobs.Where{$_.State -eq 'Failed'}.Count -And $FailedJobs.Count -gt 0)
            )
        )
    }

    'Finished' | WriteScreenInfo -ScriptStart $StartTime -PassThru | WriteCMLogEntry -Component 'Deinitialisation'

    if ($PSCmdlet.ParameterSetName -eq 'ByChoosingConfigMgrCollection') {
        Write-Host 'Press any key to quit'
        [void][System.Console]::ReadKey($true)
    }
    else {
        $Result
    }

}