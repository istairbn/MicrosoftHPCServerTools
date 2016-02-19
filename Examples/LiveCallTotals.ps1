<#
    .Synopsis
    This calculates the current load on grid at the current time. 
    
    .Parameter Wait
    Length of the Loop

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable#>[CmdletBinding()]Param([Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)][int]$Wait = 30,

[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)][String]$Scheduler = $env:CCP_SCHEDULER
)

Try{
    Import-Module -Name .\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\deployed-bundles\MicrosoftHPCApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force 
    Add-PSSnapin Microsoft.hpc
}Catch [System.Exception]{    Write-Error $Error.ToString()    $Error.Clear()}
While(1){
    Get-HPCClusterWorkload -Scheduler $Scheduler | ConvertTo-LogscapeJSON

    Sleep($Wait)
}