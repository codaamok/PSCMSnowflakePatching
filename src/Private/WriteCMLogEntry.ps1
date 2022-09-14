function WriteCMLogEntry {
    <#
    .SYNOPSIS
    Write to log file in CMTrace friendly format.
    .DESCRIPTION
    Half of the code in this function is Cody Mathis's. I added log rotation and some other bits, with help of Chris Dent for some sorting and regex. Should find this code on the WinAdmins GitHub repo for configmgr.
    .OUTPUTS
    Writes to $Folder\$FileName and/or standard output.
    .LINK
    https://github.com/winadminsdotorg/SystemCenterConfigMgr
    #>
    param (
        [parameter(Mandatory = $true, HelpMessage = 'Value added to the log file.', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Value,
        [parameter(Mandatory = $false, HelpMessage = 'Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('1', '2', '3')]
        [string]$Severity = 1,
        [parameter(Mandatory = $false, HelpMessage = "Stage that the log entry is occuring in, log refers to as 'component'.")]
        [ValidateNotNullOrEmpty()]
        [string]$Component,
        [parameter(Mandatory = $true, HelpMessage = 'Name of the log file that the entry will written to.')]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,
        [parameter(Mandatory = $true, HelpMessage = 'Path to the folder where the log will be stored.')]
        [ValidateNotNullOrEmpty()]
        [string]$Folder,
        [parameter(Mandatory = $false, HelpMessage = 'Set timezone Bias to ensure timestamps are accurate.')]
        [ValidateNotNullOrEmpty()]
        [int32]$Bias,
        [parameter(Mandatory = $false, HelpMessage = 'Maximum size of log file before it rolls over. Set to 0 to disable log rotation.')]
        [ValidateNotNullOrEmpty()]
        [int32]$MaxLogFileSize = 0,
        [parameter(Mandatory = $false, HelpMessage = 'Maximum number of rotated log files to keep. Set to 0 for unlimited rotated log files.')]
        [ValidateNotNullOrEmpty()]
        [int32]$MaxNumOfRotatedLogs = 0
    )
    begin {
        $LogFilePath = Join-Path -Path $Folder -ChildPath $FileName
    }
    # Determine log file location
    process {
        foreach ($_Value in $Value) {
            if ((([System.IO.FileInfo]$LogFilePath).Exists) -And ($MaxLogFileSize -ne 0)) {

                # Get log size in bytes
                $LogFileSize = [System.IO.FileInfo]$LogFilePath | Select-Object -ExpandProperty Length
        
                if ($LogFileSize -ge $MaxLogFileSize) {
        
                    # Get log file name without extension
                    $LogFileNameWithoutExt = $FileName -replace ([System.IO.Path]::GetExtension($FileName))
        
                    # Get already rolled over logs
                    $RolledLogs = "{0}_*" -f $LogFileNameWithoutExt
                    $AllLogs = Get-ChildItem -Path $Folder -Name $RolledLogs -File
        
                    # Sort them numerically (so the oldest is first in the list)
                    $AllLogs = $AllLogs | Sort-Object -Descending { $_ -replace '_\d+\.lo_$' }, { [Int]($_ -replace '^.+\d_|\.lo_$') }
                
                    ForEach ($Log in $AllLogs) {
                        # Get log number
                        $LogFileNumber = [int32][Regex]::Matches($Log, "_([0-9]+)\.lo_$").Groups[1].Value
                        switch (($LogFileNumber -eq $MaxNumOfRotatedLogs) -And ($MaxNumOfRotatedLogs -ne 0)) {
                            $true {
                                # Delete log if it breaches $MaxNumOfRotatedLogs parameter value
                                $DeleteLog = Join-Path $Folder -ChildPath $Log
                                [System.IO.File]::Delete($DeleteLog)
                            }
                            $false {
                                # Rename log to +1
                                $Source = Join-Path -Path $Folder -ChildPath $Log
                                $NewFileName = $Log -replace "_([0-9]+)\.lo_$",("_{0}.lo_" -f ($LogFileNumber+1))
                                $Destination = Join-Path -Path $Folder -ChildPath $NewFileName
                                [System.IO.File]::Copy($Source, $Destination, $true)
                            }
                        }
                    }
        
                    # Copy main log to _1.lo_
                    $NewFileName = "{0}_1.lo_" -f $LogFileNameWithoutExt
                    $Destination = Join-Path -Path $Folder -ChildPath $NewFileName
                    [System.IO.File]::Copy($LogFilePath, $Destination, $true)
        
                    # Blank the main log
                    $StreamWriter = [System.IO.StreamWriter]::new($LogFilePath, $false)
                    $StreamWriter.Close()
                }
            }
        
            # Construct time stamp for log entry
            switch -regex ($Bias) {
                '-' {
                    $Time = [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), $Bias)
                }
                Default {
                    $Time = [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), '+', $Bias)
                }
            }
        
            # Construct date for log entry
            $Date = (Get-Date -Format 'MM-dd-yyyy')
        
            # Construct context for log entry
            $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        
            # Construct final log entry
            $LogText = [string]::Format('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">', $_Value, $Time, $Date, $Component, $Context, $Severity, $PID)
        
            # Add value to log file
            try {
                $StreamWriter = [System.IO.StreamWriter]::new($LogFilePath, 'Append')
                $StreamWriter.WriteLine($LogText)
                $StreamWriter.Close()
            }
            catch  {
                Write-Error $_ -ErrorAction $ErrorActionPreference
            }
        }
    }
}