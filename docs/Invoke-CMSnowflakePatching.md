---
external help file: PSCMSnowflakePatching-help.xml
Module Name: PSCMSnowflakePatching
online version:
schema: 2.0.0
---

# Invoke-CMSnowflakePatching

## SYNOPSIS
Invoke software update installation for a ConfigMgr client, an array of clients, or by ConfigMgr collection.

## SYNTAX

### ByChoosingConfigMgrCollection (Default)
```
Invoke-CMSnowflakePatching [-ChooseCollection] [-AllowReboot] [-Retry <Int32>] [<CommonParameters>]
```

### ByComputerName
```
Invoke-CMSnowflakePatching -ComputerName <String[]> [-AllowReboot] [-Retry <Int32>] [<CommonParameters>]
```

### ByConfigMgrCollectionId
```
Invoke-CMSnowflakePatching -CollectionId <String> [-AllowReboot] [-Retry <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Invoke software update installation for a ConfigMgr client, an array of clients, or by ConfigMgr collection.

The function will attempt to install all available updates on a target system.
By default it will not reboot or 
retry failed installations.

You can pass a single, or array of, computer names, or you can specify a ConfigMgr collection ID.
Alternatively,
you can use the ChooseCollection switch which will present a searchable list of all ConfigMgr device collections
to choose from in an Out-GridView window.

If ComputerName, ChooseCollection, and CollectionId parameters are not used, the ChooseCollection is the default
parameter set.

If multiple ConfigMgr clients are in scope, all will be processed and monitored asyncronously using jobs.
The
function will not immediately return.
It will wait until all jobs are no longer running.

Progress will be written as host output to the console, and log file in the %temp% directory.

An output pscustomobject will be returned at the end if either the ComputerName or CollectionId parameters
were used.
If the ChooseCollection switch was used, no output object is returned (progress will still be written
to the host). 

There will be an output object per target client.
It will contain properties such as result, updates installed, 
whether a pending reboot is required, and how many times a system rebooted and how
many times software update installations were retried.

A system can be allowed to reboot and retry multiple times with the AllowReboot or Retry parameter (or both).

It is recommended you read my blog post to understand the various ways in how you can use this function: 
https://adamcook.io/p/patching-snowflakes-with-configMgr-and-powerShell

## EXAMPLES

### EXAMPLE 1
```
Invoke-CMSnowflakePatching -ComputerName 'ServerA', 'ServerB' -AllowReboot
```

Will invoke software update installation on 'ServerA' and 'ServerB' and reboot the systems if any updates return
a soft or hard pending reboot.

### EXAMPLE 2
```
Invoke-CMSnowflakePatching -ChooseCollection -AllowReboot
```

An Out-GridView dialogue will be preented to the user to choose a ConfigMgr device collection.
All members of
the collection will be targted for software update installation.
They will be rebooted if any updates
return a soft or hard pending reboot.

### EXAMPLE 3
```
Invoke-CMSnowflakePatching -CollectionId P0100016 -AllowReboot
```

Will invoke software update installation on all members of the ConfigMgr device collection ID P0100016.
They
will be rebooted if any updates return a soft or hard pending reboot.

## PARAMETERS

### -ComputerName
Name of the remote systems you wish to invoke software update installations on.
This parameter cannot be used with the ChooseCollection or CollectionId parameters.

```yaml
Type: String[]
Parameter Sets: ByComputerName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ChooseCollection
A PowerShell Out-GridView window will appear, prompting you to choose a ConfigMgr device collection. 
All members of this collection will be patched.
This parameter cannot be used with the ComputerName or CollectionId parameters.

```yaml
Type: SwitchParameter
Parameter Sets: ByChoosingConfigMgrCollection
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CollectionId
A ConfigMgr collection ID of whose members you intend to patch.
All members of this collection will be patched.
This parameter cannot be used with the ComputerName or ChooseCollection parameters.

```yaml
Type: String
Parameter Sets: ByConfigMgrCollectionId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowReboot
If an update returns a soft or hard pending reboot, specifying this switch will allow the system to be rebooted
after all updates have finished installing.
By default, the function will not reboot the system(s). 
More often than not, reboots are required in order to finalise software update installation.
Using this switch
and allowing the system(s) to reboot if required ensures a complete patch cycle.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Retry
Specify the number of retries you would like to script to make when a software update install failure is detected.
In other words, if software updates fail to install, and you specify 2 for the Retry parameter, the script will
retry installation twice.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function does not accept input from the pipeline.
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS
