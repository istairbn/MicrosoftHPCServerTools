Param(
    [CmdletBinding()]
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $PositionFolder=".\HPCAppRecords_DONOTREMOVE"
    )
Try{
    Import-Module -Name .\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\deployed-bundles\MicrosoftHPCApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force 
    Add-PSSnapin Microsoft.hpc
}Catch [System.Exception]{    Write-Error $Error.ToString()    $Error.Clear()}Set-Culture EN-GBIf(Test-Path $PositionFolder){Write-Verbose "$PositionFolder Exists"}Else{    $X = New-Item $PositionFolder -Type Directory }$Rows = Get-HPCCoreUtilisation -Scheduler $Scheduler -OnlyCollectOnce $True -PositionFolder $PositionFolderForEach($Row in $Rows){ $Row | ConvertTo-LogscapeCSV -AddHeaders $False -Timestamp $False }