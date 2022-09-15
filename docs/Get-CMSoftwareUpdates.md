---
external help file: PSCMSnowflakePatching-help.xml
Module Name: PSCMSnowflakePatching
online version:
schema: 2.0.0
---

# Get-CMSoftwareUpdates

## SYNOPSIS
Retrieve all of the software updates available on a local or remote client.

## SYNTAX

```
Get-CMSoftwareUpdates [[-ComputerName] <String>] [[-Filter] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieve all of the software updates available on a local or remote client.

This function is called by Invoke-CMSnowflakePatching.

The software updates are retrieved from the CCM_SoftwareUpdate WMI class, including all its properties.

## EXAMPLES

### EXAMPLE 1
```
Get-CMSoftwareUpdates -ComputerName 'ServerA' -Filter 'ArticleID = "5016627"'
```

Queries remote system 'ServerA' to see if software update with article ID 5016627 is available.
If nothing returns, the update is not available to install.

## PARAMETERS

### -ComputerName
Name of the remote system you wish to retrieve available software updates from.
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

### -Filter
WQL query filter used to filter the CCM_SoftwareUpdate class.
If omitted, the query will execute without a filter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

### Microsoft.Management.Infrastructure.CimInstance
## NOTES

## RELATED LINKS
