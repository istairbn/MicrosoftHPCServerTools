<#        .Synopsis        This script automatically scales Azure Nodes        .Parameter Scheduler
        Determines the scheduler used - defaults to the environment variable                .Example        Azure Node Balancer.ps1        .Notes                 .Link        www.excelian.com#>    [CmdletBinding()]Param(    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $jobTemplates,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $InitialNodeGrowth=10,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $NodeGroup = @("AzureNodes","ComputeNodes"),

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $NodeGrowth=5,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $TemplateSwitchNodeGrowth=3,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $CallQueueThreshold=2000,

    [Parameter (Mandatory=$False)]
    [bool] 
    $UndeployAzure=$True,

    [Parameter (Mandatory=$False)]
    [bool] 
    $SwitchInternalNodeTemplates=$True,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $Sleep=30,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $NumOfQueuedJobsToGrowThreshold=1,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $GridMinsRemainingThreshold= 20,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $NodeTemplates,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [int]
    $ShrinkThreshold = 6,

    [Parameter (Mandatory=$False)]
    [bool]
    $Logging=$False,

    [Parameter (Mandatory=$False)]
    [String]
    $LogFilePrefix="AzureNodeBalancer"
)

Try{
    Import-Module -Name .\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\lib\MicrosoftHPCServerTools.psm1  -Force -ErrorAction SilentlyContinue
    Import-Module -Name .\deployed-bundles\MicrosoftHPCApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force -ErrorAction SilentlyContinue
    Add-PSSnapin Microsoft.hpc
}Catch [System.Exception]{    Write-LogError $Error.ToString()    $Error.Clear()}$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
Write-LogInfo "Starting Autoscaling"
$PreviousIdleNodeCount = 0
Write-Output "Scheduler:$Scheduler
        jobTemplates:$jobTemplates
        InitialNodeGrowth:$InitialNodeGrowth
        ExcludedNodes:$ExcludedNodes
        NodeGroup:$NodeGroup
        NodeGrowth:$NodeGrowth
        CallQueueThreshold:$CallQueueThreshold
        UndeployAzure:$UndeployAzure
        SwitchInternalNodeTemplates:$SwitchInternalNodeTemplates
        Sleep:$Sleep
        NumOfQueuedJobsToGrowThreshold:$NumOfQueuedJobsToGrowThreshold
        GridMinsRemainingThreshold:$GridMinsRemainingThreshold
        NodeTemplates:$NodeTemplates
        ExcludedNodeTemplates:$ExcludedNodeTemplates
        ExcludedGroups:$ExcludedGroups
        ShrinkThreshold:$ShrinkThreshold
        Logging:$Logging
        LogFilePrefix:$LogFilePrefix"

While($elapsed.Elapsed.Hours -lt 1){

    $ActiveJobs = Get-HPCClusterActiveJobs -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -jobTemplates $JobTemplates
    
    If($ActiveJobs -ne $Null){
        $Count = $ActiveJobs.Count
    }
    Else{
        $Count = 0
    }

    Write-LogInfo "Jobs:$Count Scheduler:$Scheduler" -Logging $Logging -LogFilePrefix $LogFilePrefix 

    If($Count -ne 0){
        $Growth = Invoke-HPCClusterHybridScaleUp -Scheduler $Scheduler -jobTemplates $jobTemplates -InitialNodeGrowth $InitialNodeGrowth -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates -NodeGrowth $NodeGrowth -CallQueueThreshold $CallQueueThreshold -NumOfQueuedJobsToGrowThreshold $NumOfQueuedJobsToGrowThreshold -GridMinsRemainingThreshold $GridMinsRemainingThreshold -NodeTemplates $NodeTemplates -Logging $Logging -LogFilePrefix $LogFilePrefix
        
        If($Growth.HasGrown -eq $False -and $Growth.NeedsToGrow -eq $True -and $SwitchInternalNodeTemplates -eq $True){
           
            If(Invoke-HPCClusterSwitchNodesToRequiredTemplate -NodeTemplates $NodeTemplates -NodeGroup ComputeNodes -JobTemplates $jobTemplates -Logging $logging -LogFilePrefix $LogFilePrefix -Scheduler $Scheduler -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -NodeGrowth $TemplateSwitchNodeGrowth){
                Write-LogInfo "Action:TemplateSwitched"
            }
            Else{
                Write-LogInfo "Action:NOTHING Unable to migrate templates"
            }
        }
    }


    Else{
        Write-LogInfo "Action:NOTHING No Growth Required"
    }

    $ShrinkCheck = Get-HPCClusterShrinkCheck -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -NodeGroup $NodeGroup -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups -NodeTemplates $NodeTemplates
    
    If($ShrinkCheck.Shrink -eq $True){
        $IdleNodeCount = $ShrinkCheck.IdleNodes.Count
        If($PreviousIdleNodeCount -ne $IdleNodeCount){
            $PreviousIdleNodeCount = $IdleNodeCount
            $COUNTER = 0
            Write-LogInfo "Counter:$COUNTER ShrinkThreshold:$ShrinkThreshold IdleNodes:$IdleNodeCount Action:NODECOUNTCHANGE" 
        }
        Else{
            $COUNTER += 1
            Write-LogInfo "Counter:$COUNTER  ShrinkThreshold:$ShrinkThreshold IdleNodes:$IdleNodeCount Action:NODECOUNTCONSTANT"
        }
    }
    Else{
        $PreviousIdleNodeCount = 0
        Write-LogInfo "Action:NOTHING"
    }
    $SHRINK = $False

    If($ShrinkCheck.SHRINK -eq $True -and $Counter -gt $ShrinkThreshold){
        $SHRINK = $True
    }
    
    If($SHRINK -eq $True){
        Invoke-HPCClusterHybridShrink -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -UndeployAzure $UndeployAzure -NodeTemplates $NodeTemplates
    }

    sleep $Sleep

}
Write-LogInfo "Hour has elapsed. Restarting"