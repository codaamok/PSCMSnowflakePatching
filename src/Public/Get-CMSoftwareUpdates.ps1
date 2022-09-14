function Get-CMSoftwareUpdates {
    <#
    .SYNOPSIS
        Retrieve all of the software updates available on a local or remote client.
    .DESCRIPTION
        Retrieve all of the software updates available on a local or remote client.
    .PARAMETER ComputerName
        Name of the remote system you wish to retrieve available software updates from. If omitted, it will execute on localhost.
    .PARAMETER Filter
        WQL query filter used to filter the CCM_SoftwareUpdate class. If omitted, the query will execute without a filter.
    .EXAMPLE
        Get-CMSoftwareUpdates -ComputerName 'ServerA' -Filter 'ArticleID = "5016627"'

        Queries remote system 'ServerA' to see if software update with article ID 5016627 is available. If nothing returns, the update is not available to install.
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
        [Parameter()]
        [String]$Filter
    )

    $CimSplat = @{
        Namespace    = 'root\CCM\ClientSDK'
        ClassName    = 'CCM_SoftwareUpdate'
        ErrorAction  = 'Stop'
    }

    if ($PSBoundParameters.ContainsKey('ComputerName')) {
        $CimSplat['ComputerName'] = $ComputerName
    }
    

    if ($PSBoundParameters.ContainsKey('Filter')) {
        $CimSplat['Filter'] = $Filter
    }
    
    try {
        [CimInstance[]](Get-CimInstance @CimSplat)
    }
    catch {
        Write-Error $_ -ErrorAction $ErrorActionPreference
    }
}