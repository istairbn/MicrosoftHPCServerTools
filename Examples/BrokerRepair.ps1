    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [String]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter(Mandatory=$False)]
    [UInt16]
    $BrokerThreshold = 2,

    [Parameter(Mandatory=$False)]
    [UInt16]
    [ValidateRange(5,60)]
    $Wait = 5
    )
Try{
    Import-Module -Name .\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\deployed-bundles\HPCHybridAutoScalerApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force -ErrorAction SilentlyContinue
    Add-PSSnapin Microsoft.hpc
}Catch [System.Exception]{    Write-LogError $Error.ToString()    $Error.Clear()}

$SW = [system.diagnostics.stopwatch]::StartNew()
While($Sw.Elapsed.Hours -lt 2){
    Invoke-HPCClusterBrokerRepair -Scheduler $Scheduler -BrokerThreshold $BrokerThreshold
    Sleep ($Wait * 60)
}
