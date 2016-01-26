#------------------------------------------------------------------------------
#Script: Get-HPCData.ps1
#Author: Benjamin Newton - Excelian 
#Version 1.0.0
#Keywords: HPC,Environment Management
#-------------------------------------------------------------------------------

<# 
   .Synopsis 
    This script 

   .Parameter Scheduler
   Controls which scheduler is used. Assumes the default

   .Parameter Destination
   Where the JSON Output should be sent. Defaults to local file

   .Parameter FetchServices
   If True, will fetch service names as well. If false, will not. 

   .Parameter ServiceConfigLocation
   If collecting the Services, the Service location on the scheduler. Set to the default. 

   .Example  
    .\Get-HPCData.ps1 -Scheduler HOSTNAME -Destination D:\MyDirectory\MyGrid\ClusterSettings.txt -FetchServices $True 

   .Notes 
    The prerequisite for running this script is the Microsoft HPC Server 2012 Client Utilities - It needs the Powershell Commands

   .Link 
   www.excelian.com
#>

Param(
[CmdletBinding()]
[Parameter (Mandatory=$False)]
[string] 
$Scheduler=$Env:CCP_SCHEDULER,

[Parameter (Mandatory=$False)]
[string] 
$Destination=".\HPCClusterElements.txt",

[Parameter (Mandatory=$False)]
[bool] 
$FetchServices=$True,

[Parameter (Mandatory=$False)]
[string] 
$ServiceConfigLocation="HpcServiceRegistration"
)

    Import-Module -Name .\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\deployed-bundles\MicrosoftHPCApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force 
    Add-PSSnapin Microsoft.hpc

Get-HPCClusterElements -Logging $False -Scheduler $Scheduler -FetchServices $FetchServices -ServiceConfigLocation $ServiceConfigLocation | ConvertTo-JSON | Out-File -FilePath $Destination
