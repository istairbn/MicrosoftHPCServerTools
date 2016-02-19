<#        .Synopsis        This script collects the ClusterProperty data
        .Parameter Scheduler
        Determines the scheduler used - defaults to the environment variable                .Example        ClusterProperty.ps1        .Notes        Fires once, does not loop.         .Link        www.excelian.com#>    [CmdletBinding()]Param([Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)][String]$Scheduler = $env:CCP_SCHEDULER
)

Try{
    Import-Module -Name .\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\deployed-bundles\MicrosoftHPCApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force 
    Add-PSSnapin Microsoft.hpc
}Catch [System.Exception]{    Write-LogError $Error.ToString()    $Error.Clear()}
$OUT = Get-HpcClusterProperty -Scheduler $Scheduler -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
$TIMESTAMP = Get-Date -Format "yyyy/MM/dd HH:mm:ss zzz"
$ARRAY = @()
 foreach ($ELEMENT in $OUT){
    $LINE = [char]34+$ELEMENT.Name+[char]34+":"+[char]34+$ELEMENT.Value+[char]34+","
    $ARRAY += $LINE
 }

$String = $TIMESTAMP + " {" + $ARRAY + " }"
Write-Host $String.replace(", }"," }")
