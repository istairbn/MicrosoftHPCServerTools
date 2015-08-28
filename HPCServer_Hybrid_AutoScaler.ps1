#------------------------------------------------------------------------------
#Script: HPC Server Hybrid Grid AutoScaler.ps1
#Author: Benjamin Newton - Excelian - Code Adapted from AzureAutoGrowShrink.ps1
#Version 1.0.0
#Keywords: HPC,Azure Paas, Auto grow and Shrink, Calls
#Comments:This adaptation takes Call queue and Grid time into consideration
#-------------------------------------------------------------------------------

<# 
   .Synopsis 
    This script is used to automatically grow and shrink a Microsoft HPC Pack cluster based on queued jobs, Calls remaining and minutes of work remaining. It is compatible with SOA jobs. It includes the ability to swap NodeTemplates according to the Default Job Template groups - so you can use Groups as discriminators. To do so, you should ensure that each Job Template has a Default Group and that Group should only be assigned to a certain Node Template.

   .Parameter NodeTemplates
    Specifies the names of the node templates to define the scope for the nodes to grow and shrink. If not specified (the default value is @()), ALL nodes will be specified. Therefore, if you configure the $NodeType parameter, be sure to configure this to a suitable AzureNode Template.

   .Parameter JobTemplates
    Specifies the names of the job templates to define the workload for which the nodes to grow. If not specified (the default value is @()), all active jobs are in scope for check.

    .Parameter $NodeGroup
    Which Nodes can be affected. Defaults to AzureNodes AND ComputeNodes. If you only want to automateone type, select this. 

    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

   .Parameter Wait
    The time in seconds between checks to Grow or shrink. Default is 60

   .Parameter CallQueueThreshold
    The number of queued calls required to set off a growth of Nodes.Default is 2000

   .Parameter NumOfQueuedJobsToGrowThreshold
    The number of queued jobs required to set off a growth of Nodes. The default is 1. For SOA sessions, this should be set to 1 

   .Parameter GridMinsRemainingThreshold
    The time in minutes, of remaining Grid work. If this threshold is exceeded, more Nodes will be allocated. Default is 30

   .Parameter InitialNodeGrowth
    The initial minimum number of nodes to grow if all the nodes in scope are NotDeployed or Stopped(Deallocated). Default is 10

   .Parameter NodeGrowth
    The amount of Nodes to grow if there are already some Nodes in scope allocated. Compare with $NumInitialNodesToGrow. Default is 5

   .Parameter ShrinkCheckIdleTimes
    The number of continuous shrink checks to indicate that nodes are idle. Default is 3

   .Parameter Logging
    Whether the script creates a Log file or not - location determined by the LogFilePrefix. Default is False

   .Parameter TimeLimit
    How many minutes should the script run for before turning off. If 0, the script runs indefinitely. Default is 0.

   .Parameter LogFilePrefix
    Specifies the prefix name of the log file, you can include the path, by default the log will be in current working directory

   .Parameter ExtraNodesGrowRatio
    Specifies additional nodes to grow, because it can take a long time to start certain Azure nodes to reach a growth target. The default value is 0. For example, a value of 10 indicates that the cluster will grow 110% of the nodes.

   .Example 
    .\HPCServer Hybrid Grid Autoscaler.ps1 -NodeTemplates @('Default AzureNode Template') -NodeType AzureNodes -NumOfQueuedJobsPerNodeToGrow 10 -NumOfQueuedJobsToGrowThreshold 1 -InitialNodeGrowth 15 -Wait 5 -NodeGrowth 3 -ShrinkCheckIdleTimes 10 

   .Example  
    .\HPCServer Hybrid Grid Autoscaler.ps1 -NodeTemplates 'Default AzureNode Template' -JobTemplates 'Job Template 1' -NodeType APPLICATION_GROUP -CallQueueThreshold 2000 -GridMinsRemaining 50 -LogFilePrefix C:\LogFiles\MyAutoGrowShrinkLog

   .Notes 
    The prerequisites for running this script:
    1. Add the Azure nodes or the Azure VMs before running the script.
    2. This is not compatibile with the deprecated IAAS VMs. Use the Worker Roles.
    3. The HPC cluster should be running at least HPC Pack 2012 R2 Update 1
    4. Each Job Template must have a default group and those groups should be assigned only to one Node Template. 
    5. This requires the HPCServer_AutoScalrTools Module

   .Link 
   www.excelian.com
#>

Param(
[CmdletBinding()]
[Parameter (Mandatory=$False)]
[string[]] 
$NodeTemplates=@(),

[Parameter (Mandatory=$False)]
[string[]] 
$NodeGroup=@("AzureNodes","ComputeNodes"),

[Parameter (Mandatory=$False)]
[string[]] 
$JobTemplates=@(),

[Parameter (Mandatory=$False)]
[ValidateRange(0,[Int]::MaxValue)]
[Int] 
$Wait = 30,

[Parameter (Mandatory=$False)]
[ValidateRange(0,[Int]::MaxValue)]
[Int] 
$InitialNodeGrowth=10,

[Parameter (Mandatory=$False)]
[ValidateRange(0,[Int]::MaxValue)]
[Int] 
$NodeGrowth=5,

[Parameter (Mandatory=$False)]
[ValidateRange(0,[Int]::MaxValue)]
[Int] 
$CallQueueThreshold=1000,

[Parameter (Mandatory=$False)]
[ValidateRange(0,[Int]::MaxValue)]
[Int] 
$NumOfQueuedJobsToGrowThreshold=1,

[Parameter (Mandatory=$False)]
[ValidateRange(0,[Int]::MaxValue)]
[Int] 
$GridMinsRemainingThreshold= 40,

[Parameter (Mandatory=$False)]
[bool]
$Logging=$False,

[Parameter (Mandatory=$False)]
[String]
$LogFilePrefix="HPCServer_Hybrid_AutoScaler",

[Parameter (Mandatory=$False)]
[ValidateRange(0,[Int]::MaxValue)]
[Int] 
$TimeLimit=0,

[Parameter (Mandatory=$False)]
[ValidateRange(1,[Int]::MaxValue)]
[int]
$ShrinkCheckIdleTimes=3,

[Parameter (Mandatory=$False)]
[string[]]
$ExcludedGroups = @(),

[Parameter (Mandatory=$False)]
[string[]]
$ExcludedNodeTemplates=@(),

[Parameter (Mandatory=$False)]
[string[]]
$ExcludedNodes=@()
)

$error.clear()
#Initial preparation 
Try{
    Import-Module -Name .\HPCServer_AutoScaleTools.psm1 -ErrorAction SilentlyContinue -Force

    Add-PSSnapIn Microsoft.HPC;

    $timeout = new-timespan -Minutes $TimeLimit
    $sw = [diagnostics.stopwatch]::StartNew()

    LogInfo -message "Element:Autoscaler Action:START TimeLimit:$TimeLimit Msg:`"Starting Auto-Scaling`"" -Logging $Logging -LogFilePrefix $LogFilePrefix 
    LogInfo -message "Element:Autoscaler Action:ParamCheck NodeTemplates:$NodeTemplates NodeGroup:$NodeGroup JobTemplates:$JobTemplates Wait:$Wait InitialNodeGrowth:$InitialNodeGrowth NodeGrowth:$NodeGrowth" -Logging $Logging -LogFilePrefix $LogFilePrefix
    LogInfo -message "Element:Autoscaler Action:ParamCheck CallQueueThreshold:$CallQueueThreshold NumOfQueuedJobsToGrowThreshold:$NumOfQueuedJobsToGrowThreshold GridMinsRemainingThreshold:$GridMinsRemainingThreshold" -Logging $Logging -LogFilePrefix $LogFilePrefix
    LogInfo -message "Element:Autoscaler Action:ParamCheck Logging:$Logging LogFilePrefix:$LogFilePrefix TimeLimit:$TimeLimit ShrinkCheckIdleTimes:$ShrinkCheckIdleTimes" -Logging $Logging -LogFilePrefix $LogFilePrefix
    LogInfo -message "Element:Autoscaler Action:ParamCheck ExcludedGroups:$ExcludedGroups ExcludedNodeTemplates:$ExcludedNodeTemplates ExcludedNodes:$ExcludedNodes" -Logging $Logging -LogFilePrefix $LogFilePrefix
   
    if($TimeLimit -gt 0)
        {
            $conditions = ($sw.elapsed -lt $timeout)
        }
    else
        {
            $conditions = 1
        }

    $ShrinkCheck = 0
    }

Catch [System.Exception]{
        Return $Error
        $Error.Clear()
    }
#Begin the Loop
while($conditions){

    $JobCount = ActiveJobCount -Logging $Logging -LogFilePrefix $LogFilePrefix

    Try{
        If($JobCount -gt 0){
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "Element:GrowCheck Action:BEGINNING Msg:`"Jobs running or in Queue`" JobCount:$JobCount"
            $Jobs = ActiveJobs -Logging $Logging -LogFilePrefix $LogFilePrefix -jobTemplates $JobTemplates
            $GrowCheck = GridWorkload -Logging $Logging -LogFilePrefix $LogFilePrefix -jobTemplates $JobTemplates | GrowCheck -activeJobs $Jobs -CallQueueThreshold $CallQueueThreshold -NumOfQueuedJobsToGrowThreshold $NumOfQueuedJobsToGrowThreshold -GridMinsRemainingThreshold $GridMinsRemainingThreshold -LogFilePrefix $LogFilePrefix -Logging $Logging
            $CurrentState = ClusterStatus -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups
            
            If($GrowCheck -eq $True){
                If($CurrentState.BusyNodes.Count -eq 0){
                   LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "Element:GrowCheck Action:GROWING Msg:`"Jobs running or in Queue`" JobCount:$JobCount BusyNodeCount:0"
                   NodeGrowth -LogFilePrefix $LogFilePrefix -Logging $Logging -NodeGroup $NodeGroup -NodeTemplates $NodeTemplates -InitialNodeGrowth $InitialNodeGrowth -NodeGrowth $NodeGrowth -ExcludedNodes $ExcludedNodes 
                }

                ElseIf($CurrentState.IdleNodes.Count -ne 0){

                    $ReadyCheck = IdleReadyNodesAvailable -Logging $Logging -LogFilePrefix $LogFilePrefix -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes
                    $ChangeCheck = IdleDifferentNodesAvailable -Logging $Logging -LogFilePrefix $LogFilePrefix -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes
            
                    If($ReadyCheck -eq $True){
                        $ReadyNodes = IdleReadyNodes -Logging $Logging -LogFilePrefix $LogFilePrefix -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes
                        NodeGrowth -LogFilePrefix $LogFilePrefix -Logging $Logging -NodeGroup $NodeGroup -NodeTemplates $NodeTemplates -InitialNodeGrowth $InitialNodeGrowth -NodeGrowth $NodeGrowth -NodesToGrow $ReadyNodes
                    }
                
                    ElseIf($ChangeCheck -eq $True){
                    $SC = IdleDifferentNodes -Logging $Logging -LogFilePrefix $LogFilePrefix -NodeGroup $NodeGroup -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -NodeGrowth $NodeGrowth

                        If($SC.Count -ne 0){
                             $Stripped = StripGroups -ExcludedGroups $ExcludedGroups -Logging $Logging -LogFilePrefix $LogFilePrefix -NodesToGrow $SC 
                             TemplateSwap -Logging $Logging -LogFilePrefix $LogFilePrefix -NodesToGrow $Stripped
                        }

                        Else{
                            NodeGrowth -LogFilePrefix $LogFilePrefix -Logging $Logging -NodeGroup $NodeGroup -NodeTemplates $NodeTemplates -InitialNodeGrowth $InitialNodeGrowth -NodeGrowth $NodeGrowth
                        }
                    }
                    <# Node Balance Commented out until we can get duplication issues fixed 
                    Else{
                        $Balance = NodeBalance -Logging $Logging -LogFilePrefix $LogFilePrefix -ExcludedGroups $ExcludedGroups -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates
                        
                        If($Balance.Count -ne 0){
                            StripGroups -NodesToGrow $Balance -ExcludedGroups $ExcludedGroups
                            TemplateSwap -Logging $Logging -LogfilePrefix $LogfilePrefix -NodesToGrow $Balance 
                        }

                        Else{
                            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "Element:Balancer Action:Balanced"
                        }
                    }
                    #>
                }
                <#  BAlance action commented out for UAT - until duplication issues can be fixed.
                ElseIf($CurrentState.IdleNodes.Count -eq 0){

                    $Balance = NodeBalance -Logging $Logging -LogFilePrefix $LogFilePrefix -ExcludedGroups $ExcludedGroups -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates
                    If($Balance.Count -ne 0){
                        $Strip = StripGroups -NodesToGrow $Balance -ExcludedGroups $ExcludedGroups
                        TemplateSwap -Logging $Logging -LogfilePrefix $LogfilePrefix -NodesToGrow $Strip
                    }
                    Else{
                        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "Element:Balancer Action:Balanced"
                    }
                }
                #>

                Else{
                    NodeGrowth -LogFilePrefix $LogFilePrefix -Logging $Logging -NodeGroup $NodeGroup -NodeTemplates $NodeTemplates -InitialNodeGrowth $InitialNodeGrowth -NodeGrowth $NodeGrowth -ExcludedNodes $ExcludedNodes 
                }
            }
        }

        Else{
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "Element:GrowCheck Action:COMPLETE GrowCheck:False Msg:`"No Jobs running or in Queue`" JobCount:$JobCount"
        }
    }
    Catch [System.Exception]{
        LogError -message $Error -Logging $Logging -LogFilePrefix $LogFilePrefix
    }

    $SCheck = ShrinkCheck -Logging $Logging -LogFilePrefix $LogFilePrefix -NodeGroup $NodeGroup -NodeTemplates $NodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedGroups $ExcludedGroups
    $SHRINK = $SCheck.SHRINK

    Try{
            If($SCheck.SHRINK -eq $True){

                If($ShrinkCheck -ge $ShrinkCheckIdleTimes){
                    $SCheck | NodeShrink -LogFilePrefix $LogFilePrefix -Logging $Logging 
                    $ShrinkCheck = 0
                    }

                Else{
                    $ShrinkCheck += 1
                    LogInfo -message "Element:SHRINKCHECK Action:SHRINKCHECK TimeLimit:$TimeLimit ShrinkCheck:$SHRINKCHECK Msg:`"Add to ShrinkCheck`"" -Logging $Logging -LogFilePrefix $LogFilePrefix 
                }    
            }

            Else{    
                $ShrinkCheck = 0
                LogInfo -message "Element:SHRINKCHECK Action:SHRINKRESET TimeLimit:$TimeLimit ShrinkCheck:$SHRINKCHECK Msg:`"Reset ShrinkCheck`"" -Logging $Logging -LogFilePrefix $LogFilePrefix 
            }

        }
    Catch [System.Exception]{
        LogError -message $Error -Logging $Logging -LogFilePrefix $LogFilePrefix
    }
    
    Try{
    If($JobCount -gt 0){
        MaintainOneNodePerGroup -Logging $Logging -LogFilePrefix $LogFilePrefix -NodeGroup $NodeGroup -ExcludedGroups $ExcludedGroups -ExcludedNodes $ExcludedNodes
    }
    }
    Catch [System.Exception]{
        LogError -LogFilePrefix $LogfilePrefix -Logging $Logging -Message $Error
    }


    LogInfo -message "Element:Autoscaler Action:SLEEP" -Logging $Logging -LogFilePrefix $LogFilePrefix

    sleep $Wait
}

LogInfo -message "Element:Autoscaler Status:Offline Action:STOP TimeLimit:$TimeLimit Msg:`"Stopping Auto-Scaling`"" -Logging $Logging -LogFilePrefix $LogFilePrefix

Remove-Module -Name .\AzureGrowShrinkTools.psm1 -ErrorAction SilentlyContinue
