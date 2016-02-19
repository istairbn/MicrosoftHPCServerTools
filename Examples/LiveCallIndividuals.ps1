﻿[CmdletBinding()]

[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]

[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
)

Try{
    Import-Module -Name .\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\deployed-bundles\MicrosoftHPCApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force 
    Add-PSSnapin Microsoft.hpc
}
<#
Timestamp|Id|Template|Priority|NodeGroups|OrderBy|State|Name|Owner|RunAsUser|Project|RequestedNodes
|ExcludedNodes|AllocatedNodes|CurrentAllocation|Exclusive|RunUntilCanceled|PendingReason|ErrorMessage|FailOnTaskFail
ure|Preemptable|MinMemoryPerNode|ParentJobIds|ChildJobIds|FailDependentTasks|MaxMemoryPerNode|MinCoresPerNode|MaxCor
esPerNode|License|Progress|ProgressMessage|NotifyOnStart|NotifyOnCompletion|EmailAddress|
RequeueCount|AutoRequeueCount|Pool|ValidExitCodes|NodeGroupOp|SingleNode|EstimatedProcessMemory|PlannedCoreCount|Tas
kExecutionFailureRetryLimit|ChangeTime|SubmitTime|StartTime|EndTime|HoldUntil|RunTime|ElapsedTime|WaitTime|AutoCalcu
lateMax|AutoCalculateMin|UnitType|MaxNodes|MinNodes|MaxSockets|MinSockets|MaxCores|MinCores|NumberOfCalls|Outstandin
gCalls|CallDuration|CallsPerSecond|NumberOfTasks|ConfiguringTasksCount|QueuedTasksCount|RunningTasksCount|FinishedTa
sksCount|FailedTasksCount|CanceledTasksCount|JSON With JobEnv JobCustomProperties
#>

While(1){
    $OUT = Get-HPCClusterActiveJobs -Scheduler $Scheduler 
    ForEach($Line in $OUT){
        $Output1 = $Line | Select-Object * -ExcludeProperty JobEnv,JobCustomProperties  | ConvertTo-LogscapeCSV -Delimiter $Delimiter 
        $Output2 = $Line | Select-Object JobEnv,JobCustomProperties | ConvertTo-LogscapeJson -Timestamp $False
        $String = $Output1.ToString() + $Delimiter + $Output2.ToString()
        Write-Output $String
        }
    Sleep($Wait)
}