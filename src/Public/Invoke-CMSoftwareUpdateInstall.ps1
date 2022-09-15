function Invoke-CMSoftwareUpdateInstall {
    <#
    .SYNOPSIS
        Initiate the installation of available software updates for a local or remote client.
    .DESCRIPTION
        Initiate the installation of available software updates for a local or remote client. 

        This function is called by Invoke-CMSnowflakePatching.

        After installation is complete, regardless of success or failure, a CimInstance object from the CCM_SoftwareUpdate
        class is returned with the update(s) final state.

        The function processes syncronously, therefore it waits until the installation is complete.

        The function will timeout by default after 5 minutes waiting for the available updates to begin downloading/installing,
        and  120 minutes of waiting for software updates to finish installing. These timeouts are configurable via parameters 
        InvokeSoftwareUpdateInstallTimeoutMins and InstallUpdatesTimeoutMins respectively.
    .PARAMETER ComputerName
        Name of the remote system you wish to invoke the software update installation on. If omitted, localhost will be targetted.
    .PARAMETER Update
        A CimInstance object, from the CCM_SoftwareUpdate class, of the updates you wish to invoke on the target system.

        Use the Get-CMSoftwareUpdates function to get this object for this parameter.
    .PARAMETER InvokeSoftwareUpdateInstallTimeoutMins
        Number of minutes to wait for all updates to change state to downloading/installing, before timing out and throwing an exception.
    .PARAMETER InstallUpdatesTimeoutMins
        Number of minutes to wait for all updates to finish installing, before timing out and throwing an exception.
    .EXAMPLE
        $Updates = Get-CMSoftwareUpdates -ComputerName 'ServerA' -Filter 'ComplianceState = 0'; Invoke-CMSoftwareUpdateInstall -ComputerName 'ServerA' -Updates $Updates

        The first command retrieves all available software updates from 'ServerA', and the second command initiates the software update install on 'ServerA'.

        The default timeout values apply: 5 minutes of waiting for updates to begin downloading/installing, and 120 minutes waiting for updates to finish installing, 
        before an exception is thrown.
    .INPUTS
        This function does not accept input from the pipeline.
    .OUTPUTS
        Microsoft.Management.Infrastructure.CimInstance
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param(
        [Parameter()]
        [String]$ComputerName,
        [Parameter(Mandatory)]
        [CimInstance[]]$Update,
        [Parameter()]
        [Int]$InvokeSoftwareUpdateInstallTimeoutMins = 5,
        [Parameter()]
        [Int]$InstallUpdatesTimeoutMins = 120
    )

    NewLoopAction -LoopTimeout $InvokeSoftwareUpdateInstallTimeoutMins -LoopTimeoutType 'Minutes' -LoopDelay 15 -LoopDelayType 'Seconds' -ScriptBlock {
        try {
            $CimSplat = @{
                Namespace    = 'root\CCM\ClientSDK'
                ClassName    = 'CCM_SoftwareUpdatesManager'
                Name         = 'InstallUpdates'
                Arguments    = @{
                    CCMUpdates = [CimInstance[]]$Update
                }
                ErrorAction  = 'Stop'
            }

            if (-not [String]::IsNullOrWhiteSpace($ComputerName)) {
                $Options = New-CimSessionOption -Protocol 'DCOM'
                $CimSplat['CimSession'] = New-CimSession -ComputerName $ComputerName -SessionOption $Options -ErrorAction 'Stop'
            }

            $Result = Invoke-CimMethod @CimSplat

            if (-not [String]::IsNullOrWhiteSpace($ComputerName)) {
                Remove-CimSession $CimSplat['CimSession'] -ErrorAction 'Stop'
            }

            if ($Result.ReturnValue -ne 0) {
                $Exception = [System.Exception]::new('Failed to invoke software update(s) install, return code was {0}' -f $Result.ReturnValue)
                $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $Exception,
                    $Result.ReturnValue,
                    [System.Management.Automation.ErrorCategory]::InvalidResult,
                    $ComputerName
                )
                throw $ErrorRecord
            }
        }
        catch {
            if ($_.FullyQualifiedErrorId -notmatch '0x80041001') {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    } -ExitCondition {
        try {
            $Splat = @{
                Filter       = 'ArticleID = "{0}"' -f [String]::Join('" OR ArticleID = "', $Update.ArticleID)
                ErrorAction  = 'Stop'
            }

            if (-not [String]::IsNullOrWhiteSpace($ComputerName)) {
                $Splat['ComputerName'] = $ComputerName
            }

            $LatestUpdates = Get-CMSoftwareUpdates @Splat
            if ($LatestUpdates.EvaluationState -match '^2$|^3$|^4$|^5$|^6$|^7$') { return $true }
        }
        catch {
            if ($_.FullyQualifiedErrorId -match '0x80041001') {
                return $false
            }
            else {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    } -IfTimeoutScript {
        $Exception = [System.TimeoutException]::new('Timeout while trying to initiate update(s) install')
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
            $Exception,
            $null,
            [System.Management.Automation.ErrorCategory]::OperationTimeout,
            $ComputerName
        )
        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    }

    NewLoopAction -LoopTimeout $InstallUpdatesTimeoutMins -LoopTimeoutType 'Minutes' -LoopDelay 15 -LoopDelayType 'Seconds' -ScriptBlock {
        # Until all triggered updates are no longer in a state of downloading/installing
    } -ExitCondition {
        try {
            $Splat = @{
                Filter       = 'ArticleID = "{0}"' -f [String]::Join('" OR ArticleID = "', $Update.ArticleID)
                ErrorAction  = 'Stop'
            }

            if (-not [String]::IsNullOrWhiteSpace($ComputerName)) {
                $Splat['ComputerName'] = $ComputerName
            }

            $LastState = Get-CMSoftwareUpdates @Splat
            ($LastState.EvaluationState -match '^2$|^3$|^4$|^5$|^6$|^7$|^11$').Count -eq 0
        }
        catch {
            if ($_.FullyQualifiedErrorId -match '0x80041001') {
                return $false
            }
            else {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    } -IfTimeoutScript {
        $Exception = [System.TimeoutException]::new('Timeout while installing update(s)')
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
            $Exception,
            $null,
            [System.Management.Automation.ErrorCategory]::OperationTimeout,
            $ComputerName
        )
        $PSCmdlet.ThrowTerminatingError($ErrorRecord)
    } -IfSucceedScript {
        $LastState
    }
}