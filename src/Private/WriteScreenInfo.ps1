function WriteScreenInfo {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Inspired by PSLog in the AutomatedLab module
        https://github.com/AutomatedLab/AutomatedLab/blob/c01e2458e38811ccc4b2c58e3f958d666c39d9b9/PSLog/PSLog.psm1
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Message,
        [Parameter(Mandatory)]
        [datetime]$ScriptStart,
        [Parameter()]
        [ValidateSet("Error", "Warning", "Info", "Verbose", "Debug")]
        [string]$Type = "Info",
        [Parameter()]
        [int32]$Indent = 0,
        [Parameter()]
        [Switch]$PassThru
    )
    begin {
        $Date = Get-Date
        $TimeString = "{0:d2}:{1:d2}:{2:d2}" -f $Date.Hour, $Date.Minute, $Date.Second
        $TimeDelta = $Date - $ScriptStart
        $TimeDeltaString = "{0:d2}:{1:d2}:{2:d2}" -f $TimeDelta.Hours, $TimeDelta.Minutes, $TimeDelta.Seconds
    }
    process {
        foreach ($Msg in $Message) {
            if ($PassThru.IsPresent) { Write-Output $Msg }
            $Msg = ("- " + $Msg).PadLeft(($Msg.Length) + ($Indent * 4), " ")
            $string = "[ {0} | {1} ] {2}" -f $TimeString, $TimeDeltaString, $Msg
            switch ($Type) {
                "Error" {
                    Write-Host $string -ForegroundColor Red
                }
                "Warning" {
                    Write-Host $string -ForegroundColor Yellow
                }
                "Info" {
                    Write-Host $string
                }
                "Debug" {
                    if ($DebugPreference -eq "Continue") { Write-Host $string -ForegroundColor Cyan }
                }
                "Verbose" {
                    if ($VerbosePreference -eq "Continue") { Write-Host $string -ForegroundColor Cyan }
                }
            }
        }
    }
}