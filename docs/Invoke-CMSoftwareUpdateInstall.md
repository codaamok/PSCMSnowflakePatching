---
external help file: PSCMSnowflakePatching-help.xml
Module Name: PSCMSnowflakePatching
online version:
schema: 2.0.0
---

# Invoke-CMSoftwareUpdateInstall

## SYNOPSIS
Initiate the installation of available software updates for a local or remote client.

## SYNTAX

```
Invoke-CMSoftwareUpdateInstall [[-ComputerName] <String>] [-Update] <CimInstance[]>
 [[-InvokeSoftwareUpdateInstallTimeoutMins] <Int32>] [[-InstallUpdatesTimeoutMins] <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Initiate the installation of available software updates for a local or remote client. 

This function is called by Invoke-CMSnowflakePatching.

After installation is complete, regardless of success or failure, a CimInstance object from the CCM_SoftwareUpdate
class is returned with the update(s) final state.

The function processes syncronously, therefore it waits until the installation is complete.

The function will timeout by default after 5 minutes waiting for the available updates to begin downloading/installing,
and  120 minutes of waiting for software updates to finish installing.
These timeouts are configurable via parameters 
InvokeSoftwareUpdateInstallTimeoutMins and InstallUpdatesTimeoutMins respectively.

## EXAMPLES

### EXAMPLE 1
```
$Updates = Get-CMSoftwareUpdates -ComputerName 'ServerA' -Filter 'ComplianceState = 0'; Invoke-CMSoftwareUpdateInstall -ComputerName 'ServerA' -Updates $Updates
```

The first command retrieves all available software updates from 'ServerA', and the second command initiates the software update install on 'ServerA'.

The default timeout values apply: 5 minutes of waiting for updates to begin downloading/installing, and 120 minutes waiting for updates to finish installing, 
before an exception is thrown.

## PARAMETERS

### -ComputerName
Name of the remote system you wish to invoke the software update installation on.
If omitted, localhost will be targetted.

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

### -Update
A CimInstance object, from the CCM_SoftwareUpdate class, of the updates you wish to invoke on the target system.

Use the Get-CMSoftwareUpdates function to get this object for this parameter.

```yaml
Type: CimInstance[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InvokeSoftwareUpdateInstallTimeoutMins
Number of minutes to wait for all updates to change state to downloading/installing, before timing out and throwing an exception.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallUpdatesTimeoutMins
Number of minutes to wait for all updates to finish installing, before timing out and throwing an exception.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 120
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function does not accept input from the pipeline.
## OUTPUTS

### Microsoft.Management.Infrastructure.CimInstance
## NOTES

## RELATED LINKS
