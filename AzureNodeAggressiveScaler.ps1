<#        .Synopsis        This script automatically scales Azure Nodes        
        
        .Parameter Scheduler
        Determines the scheduler used - defaults to the environment variable                .Example        Azure Node Balancer.ps1        .Notes                 .Link        www.excelian.com#>    [CmdletBinding()]Param(    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $jobTemplates,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $InitialNodeGrowth=6,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    #$NodeGroup = @("AzureNodes","ComputeNodes"),
    $NodeGroup = @("AzureNodes"),

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $NodeGrowth=3,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $TemplateSwitchNodeGrowth=4,

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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [int]
    $AcceptableJTUtilisation = 70,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [int]
    $AcceptableNodeUtilisation = 30,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [int]
    $UnacceptableNodeUtilisation = 20,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,100)]
    [Int] 
    $TemplateUtilisationThreshold = 80, 

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
    Import-Module -Name .\deployed-bundles\HPCHybridAutoScalerApp-2.0\lib\MicrosoftHPCServerTools.psm1 -Force -ErrorAction SilentlyContinue
    Add-PSSnapin Microsoft.hpc
}Catch [System.Exception]{    Write-LogError $Error.ToString()    $Error.Clear()}

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
Write-Output "Starting Autoscaling"
$PreviousIdleNodeCount = 0
Write-Verbose "Scheduler:$Scheduler
        jobTemplates:$jobTemplates
        InitialNodeGrowth:$InitialNodeGrowth
        ExcludedNodes:$ExcludedNodes
        NodeGroup:$NodeGroup
        NodeGrowth:$NodeGrowth
        CallQueueThreshold:$CallQueueThreshold
        UndeployAzure:$UndeployAzure
        AcceptableJTUtilisation: $AcceptableJTUtilisation 
        AcceptableNodeUtilisation: $AcceptableNodeUtilisation 
        UnacceptableNodeUtilisation: $UnacceptableNodeUtilisation
        SwitchInternalNodeTemplates:$SwitchInternalNodeTemplates
        Sleep:$Sleep
        NumOfQueuedJobsToGrowThreshold:$NumOfQueuedJobsToGrowThreshold
        GridMinsRemainingThreshold:$GridMinsRemainingThreshold
        NodeTemplates:$NodeTemplates
        ExcludedNodeTemplates:$ExcludedNodeTemplates
        ExcludedGroups:$ExcludedGroups
        ShrinkThreshold:$ShrinkThreshold
        Logging:$Logging
        TemplateUtilisationThreshold:$TemplateUtilisationThreshold
        LogFilePrefix:$LogFilePrefix"
        
$NodesToRemoveMap = @{}

While($elapsed.Elapsed.Minutes -lt 30){
    Write-Verbose "Elapsed"
    Write-Verbose $Elapsed.Elapsed.Minutes

    $ActiveJobs = Get-HPCClusterActiveJobs -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -jobTemplates $JobTemplates
    
    If($ActiveJobs -ne $Null){
        $Count = $ActiveJobs.Count
    }
    Else{
        $Count = 0
    }

    Write-LogInfo "Jobs:$Count Scheduler:$Scheduler" -Logging $Logging -LogFilePrefix $LogFilePrefix 

    If($Count -ne 0){
        Invoke-HPCClusterAzureAutoScaleUp -Scheduler $Scheduler -InitialNodeGrowth $InitialNodeGrowth `
        -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates -NodeGrowth $NodeGrowth `
        -CallQueueThreshold $CallQueueThreshold -GridMinsRemainingThreshold $GridMinsRemainingThreshold -NodeTemplates $NodeTemplates `
        -Logging $Logging -LogFilePrefix $LogFilePrefix -NodeGroup $NodeGroup -TemplateUtilisationThreshold $TemplateUtilisationThreshold -JobQueueThreshold $NumOfQueuedJobsToGrowThreshold
    }

    Else{
        Write-LogInfo "Action:NOTHING No Growth Required"
    }

    $NodesToRemoveMap = Get-HPCClusterNodesToRemoveByUtilisation -Scheduler $Scheduler -ExcludedNodes $ExcludedNodes `
    -NodeGroup $NodeGroup -NodeTemplates $NodeTemplates -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedGroups $ExcludedGroups `
    -Logging $Logging -NodesToRemoveMap $NodesToRemoveMap -AcceptableJTUtilisation $AcceptableJTUtilisation -AcceptableNodeUtilisation $AcceptableNodeUtilisation `
    -UnacceptableNodeUtilisation $UnacceptableNodeUtilisation -jobTemplates $jobTemplates

    $NodesToTurnOffline = Get-HPCClusterNodesMappedToRemove -Map $NodesToRemoveMap -Threshold $ShrinkThreshold        
    
    If(@($NodesToTurnOffline).count -ne 0){
        ForEach($Node in $NodesToTurnOffline){
            $NodesToRemoveMap.Remove($Node)
        }
        $idleNodes = @() 
        $idleNodes = Get-HpcNode -Name $NodesToTurnOffline
        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "ShrinkThreshold Exceeded Nodes:$NodesToTurnOffline"
        Set-HPCClusterNodesUndeployedOrOffline -idleNodes $idleNodes -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler
    }
    Else{
        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "ShrinkThreshold $ShrinkThreshold not exceeded"
    }
    sleep $Sleep
}
Write-Verbose "Time has elapsed. Restarting"