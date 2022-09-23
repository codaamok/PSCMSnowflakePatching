| Branch | Build status | Last commit | Latest release | PowerShell Gallery | GitHub |
|-|-|-|-|-|-|
| `master` | [![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/codaamok/PSCMSnowflakePatching/Pipeline/master)](https://github.com/codaamok/PSCMSnowflakePatching/actions) | [![GitHub last commit (branch)](https://img.shields.io/github/last-commit/codaamok/PSCMSnowflakePatching/master?color=blue)](https://github.com/codaamok/PSCMSnowflakePatching/commits/master) | [![GitHub release (latest by date)](https://img.shields.io/github/v/release/codaamok/PSCMSnowflakePatching?color=blue)](https://github.com/codaamok/PSCMSnowflakePatching/releases/latest) [![GitHub Release Date](https://img.shields.io/github/release-date/codaamok/PSCMSnowflakePatching?color=blue)](https://github.com/codaamok/PSCMSnowflakePatching/releases/latest) | [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSCMSnowflakePatching?color=blue)](https://www.powershellgallery.com/packages/PSCMSnowflakePatching) | [![GitHub all releases](https://img.shields.io/github/downloads/codaamok/PSCMSnowflakePatching/total?color=blue)](https://github.com/codaamok/PSCMSnowflakePatching/releases) |

**PSCMSnowflakePatching** is a PowerShell module used to remotely invoke the install of software updates deployed to Microsoft Endpoint Configuration Manager clients.

With this module you can:

- Pass a list of one or more computer names, a ConfigMgr device collection ID, or interactively choose a ConfigMgr device collection
- For each host, invoke the install of all software updates deployed to it
- See realtime feedback and result from each patch job written to the PowerShell console
- Receive an output object when patching is complete for all hosts with the results

To read more of a discussion about how to use this module, see my blog post [Patching Snowflakes with ConfigMgr and PowerShell](https:///adamcook.io/p/patching-snowflakes-with-configmgr-and-powershell/).

## Functions

- [Invoke-CMSnowflakePatching](docs/Invoke-CMSnowflakePatching.md)
- [Invoke-CMSoftwareUpdateInstall](docs/Invoke-CMSoftwareUpdateInstall.md)
- [Get-CMSoftwareUpdates](docs/Get-CMSoftwareUpdates.md)
- [Start-CMClientAction](docs/Start-CMClientAction.md)

`Invoke-CMSnowflakePatching` is the primary function of interest in this module. The others are actually helper functions for it, however I decided to make them public functions as they might be useful for you for other needs.

## Requirements

In order to use PSCMSnowflakePatching, here are the requirements:

- For each host you wish to target for remotely invoking the install of software updates, they must be reachable using [PowerShell Remoting](https://learn.microsoft.com/en-us/powershell/scripting/learn/remoting/running-remote-commands?view=powershell-7.2). Here is the Microsoft doc for PowerShell Remote requirements: (about_Remote_Requirements](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_requirements) 
- Microsoft Endpoint Configuration Manager PowerShell module must be installed
- You, or the service running the code, must have access to Configuration Manager itself in order to retrieve device collections and its members.
- You, or the service running the code, must have permissions on the remote hosts to:
  - Reboot
  - Query WMI classes and invoke methods in the `root\CCM` namespace
    - A quick and dirty way to test, import the module and run the below safe commands and if no errors are thrown, you're probably OK:

```powershell
Start-CMClientAction -ComputerName 'hostname' -ScheduleId 'MachinePolicyEvaluation'
Get-CMSoftwareUpdates -ComputerName 'hostname'
```

## Getting started

Install and import:

```powershell
Install-Module PSCMSnowflakePatching
Import-Module PSCMSnowflakePatching
```

Make one or more update available to a target system by deploying it from Microsoft Endpoint Configuration Manager.

For example, I deployed a handful to my test collection and executed the below:

```powershell
$result = Invoke-CMSnowflakePatching -CollectionId 'P0100016'
```

`Write-Host` is used to produce realtime feedback about the process:

![](https://github.com/codaamok/codaamok.github.io-hugo/raw/master/content/post/Patching-Snowflakes-with-ConfigMgr-and-PowerShell/images/1-1.png)

Within the `$result` variable is the output object, which could be handy for your other automation needs:

![](https://github.com/codaamok/codaamok.github.io-hugo/raw/master/content/post/Patching-Snowflakes-with-ConfigMgr-and-PowerShell/images/1-2.png)

By default it doesn't reboot or make any retry attempts, but there parameters for this if you need it:

- `-AllowReboot` switch will reboot the system(s) if any update returned an exit code indicating a reboot is required
- `-Attempts` parameter will let you indicate the maximum number of retries you would like the function to install updates if there was a failure in the previous attempt

## To do

- Pass alternate credentials for connecting to remote hosts
- Consider using PendingReboot or Test-PendingReboot from the gallery to make the `IsPendingReboot` reflect more than just the newly installed updates exit code