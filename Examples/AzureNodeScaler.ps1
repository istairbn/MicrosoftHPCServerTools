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
        
$NodesToRemoveMap = @{}

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
        Invoke-HPCClusterAzureAutoScaleUp -Scheduler $Scheduler `
        -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates -NodeGrowth $NodeGrowth `
        -CallQueueThreshold $CallQueueThreshold -GridMinsRemainingThreshold $GridMinsRemainingThreshold -NodeTemplates $NodeTemplates `
        -Logging $Logging -LogFilePrefix $LogFilePrefix  
    }

    Else{
        Write-LogInfo "Action:NOTHING No Growth Required"
    }

    $OnlineAzureNodes = Get-HpCNode -GroupName AzureNodes -State Online,Offline -ErrorAction SilentlyContinue
    $OnlineComputeNodes = Get-HpCNode -GroupName ComputeNodes -State Online -ErrorAction SilentlyContinue

    If($OnlineAzureNodes.Count -ge 1){
        Write-LogInfo "Shrink Check for AzureNodes"
        $ShrinkCheck = Get-HPCClusterShrinkCheck -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -NodeGroup AzureNodes -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups -NodeTemplates $NodeTemplates
        $TurnOffIfPossible = Get-HPCNode -Name $State.IdleNodes -GroupName AzureNodes -State Offline,Online -ErrorAction SilentlyContinue -Scheduler $Scheduler 
    }
    ElseIf($State.IdleNodes.Count -ne 0){
        Write-LogInfo "Shrink Check for $NodeGroup"
        $ShrinkCheck = Get-HPCClusterShrinkCheck -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -NodeGroup $NodeGroup -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups -NodeTemplates $NodeTemplates
        $TurnOffIfPossible = Get-HPCNode -Name $State.IdleNodes -State Offline,Online -GroupName $NodeGroup -ErrorAction SilentlyContinue -Scheduler $Scheduler 
    }

    If($ShrinkCheck.Shrink -eq $True){

        $State = Get-HPCClusterStatus -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups 
        #Uncomment below if you want ALL Nodes balanced ALL the time
        #$TurnOffIfPossible = Get-HPCNode -Name $State.IdleNodes -State Offline,Online -ErrorAction SilentlyContinue -Scheduler $Scheduler 
        $IgnoreTheseNodes = @(Get-HpcNode -State Offline -GroupName ComputeNodes -ErrorAction SilentlyContinue -Scheduler $Scheduler)
    
        If($State.BusyNodes -ne 0){
            $IgnoreTheseNodes += Get-HPCNode -Name $State.BusyNodes -ErrorAction SilentlyContinue -Scheduler $Scheduler
        }

        ForEach($Node in $TurnOffIfPossible){
    
            If($NodeOfInterest = $NodesToRemoveMap.Get_Item($Node.NetBiosName)){
                $NodeOfInterest += 1
                $NodesToRemoveMap.Set_Item($Node.NetBiosName,$NodeOfInterest)
        
            }

            Else{
                $NodesToRemoveMap.Add($Node.NetBiosName,1)
            }
        }

        If($NodesToRemoveMap.Count -ne 0){
            $Output = $NodesToRemoveMap | ConvertTo-LogscapeJSON -Timestamp $False
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "NodeShrinkCounter $Output"
        }

        ForEach($Node in $IgnoreTheseNodes){
    
            If($NodeOfInterest = $NodesToRemoveMap.Get_Item($Node.NetBiosName)){
                $NodesToRemoveMap.Remove($Node.NetBiosName)
        
            }

        }

        $NodesToTurnOffline = @()


        If($NodesToRemoveMap.Count -ne 0){
         
            ForEach($item in $NodesToRemoveMap.GetEnumerator()){
                #If time to Shrink add to NodesToTurnOffline
                If($item.value -ge $ShrinkThreshold){
                    $NodesToTurnOffline += $Item.key
                }
            }
            If($NodesToTurnOffline.Count -ne 0){
                
                ForEach($Node in $NodesToTurnOffline){$NodesToRemoveMap.Remove($Node)}

                $idleNodes = @() 
                $idleNodes = Get-HpcNode -Name $NodesToTurnOffline
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "ShrinkThreshold Exceeded Nodes:$NodesToTurnOffline"
                Set-HPCClusterNodesUndeployedOrOffline -idleNodes $idleNodes -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler
            }
            Else{
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "ShrinkThreshold not exceeded"
            }
        }

    }
    sleep $Sleep

}
Write-LogInfo "Hour has elapsed. Restarting"