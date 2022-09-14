function Start-CMClientAction {
    <#
    .SYNOPSIS
        Invoke a Configuration Manager client action on a local or remote client, see https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client.
    .DESCRIPTION
        Invoke a Configuration Manager client action on a local or remote client, see https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client.
    .PARAMETER ComputerName
        Name of the remote system you wish to invoke this action on. If omitted, it will execute on localhost.
    .PARAMETER ScheduleId 
        Name of a schedule ID to invoke, see https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client.
    .EXAMPLE
        Start-CMClientAction -ScheduleId ScanByUpdateSource

        Will asynchronous start the Software Update Scan Cycle action on localhost.
    .INPUTS
        This function does not accept input from the pipeline.
    .OUTPUTS
        This function does not output any object to the pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]$ComputerName,
        [Parameter(Mandatory)]
        [TriggerSchedule]$ScheduleId
    )

    try {
        $CimSplat = @{
            Namespace    = 'root\CCM'
            ClassName    = 'SMS_Client'
            MethodName   = 'TriggerSchedule'
            Arguments    = @{
                sScheduleID = '{{00000000-0000-0000-0000-{0}}}' -f $ScheduleId.value__.ToString().PadLeft(12, '0')
            }
            ErrorAction  = 'Stop'
        }
        if ($PSBoundParameters.ContainsKey('ComputerName')) {
            $Options = New-CimSessionOption -Protocol DCOM -ErrorAction 'Stop'
            $CimSplat['CimSession'] = New-CimSession -ComputerName $ComputerName -SessionOption $Options -ErrorAction 'Stop'
        }
        
        $null = Invoke-CimMethod @CimSplat

        if ($PSBoundParameters.ContainsKey('ComputerName')) {
            Remove-CimSession $CimSplat['CimSession'] -ErrorAction 'Stop'
        }
    }
    catch {
        Write-Error $_ -ErrorAction $ErrorActionPreference
    }
}