[CmdletBinding()]Param([Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)][String]$Scheduler = $env:CCP_SCHEDULER,

[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
[string]
$PositionFolder=".\HPCAppRecords_DONOTREMOVE"
)

Try{
    Import-Module -Name .\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\deployed-bundles\MicrosoftHPCApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force -ErrorAction SilentlyContinue
    Add-PSSnapin Microsoft.hpc
}Catch [System.Exception]{    Write-Error $Error.ToString()    $Error.Clear()    Exit}
Set-Culture EN-GB
$Output = Export-HPCClusterFullJobHistory -Scheduler $Scheduler -PositionFolder $PositionFolder #-verbose
<#
JobHistoryId|JobId|RequeueId|Event|Owner|Project|Service|Template|SubmitTime|StartTime|En
dTime|EventTime|CpuTime|Runtime|MemoryUsed|NumberOfCalls|CallDuration|CallsPerSecond|Name|KernelCpuTime|UserCpuTime|
Priority|Type|Preemptable|NumberOfTasks|CanceledTasksCount|FailedTasksCount|FinishedTasksCount|License|RunUntilCance
led|IsExclusive|FailOnTaskFailure|CanceledBy|TotalTaskSeconds 
#>
ForEach($Line in $Output){ $Line | ConvertTo-LogscapeCSV -Delimiter "|" -TimeStamp $False }