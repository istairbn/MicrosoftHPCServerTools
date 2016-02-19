<#        .Synopsis        This script grabs the cluster overview
        .Parameter Scheduler
        Determines the scheduler used - defaults to the environment variable                .Parameter Wait        How long between grabs in seconds        .Example        ClusterOverview.ps1 -Wait 60        .Notes        .Link        www.excelian.com#>    [CmdletBinding()]Param(    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]    [int]    $Wait = 30,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]    [String]    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter(Mandatory=$False)]
    [switch]
    $CSV
    )

Try{
    Import-Module -Name .\MicrosoftHPCServerTools.psm1 -ErrorAction SilentlyContinue -Force
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1 -ErrorAction SilentlyContinue -Force
    Import-Module -Name .\deployed-bundles\MicrosoftHPCApp-2.0\lib\MicrosoftHPCServerTools.psm1 -ErrorAction SilentlyContinue -Force
    Add-PSSnapin Microsoft.hpc
}Catch [System.Exception]{    Write-Error $Error.ToString()    $Error.Clear()}

While(1){
    $collections = @()
    $collections += Get-HpcClusterOverview -Scheduler $Scheduler -ErrorAction SilentlyContinue -WarningAction SilentlyContinue 
    $Collections += Get-HPCClusterStatus -Scheduler $Scheduler | Select-Object ClusterName,AvailableComputeCores,PercentComputeCoresUtilised,PercentComputeCoresUnutilised,PercentTotalCoresAvailable,PercentTotalCoresUnavailable
    ForEach($Data in $collections){
        If($CSV){$Data | ConvertTo-LogscapeCSV}
        Else{$Data | ConvertTo-LogscapeJSON}
    }
    Sleep($Wait)
}
