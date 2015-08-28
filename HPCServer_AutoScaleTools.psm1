#------------------------------------------------------------------------------
#Script: AzureGrowShrinkTools.ps1
#Author: Benjamin Newton - Excelian - Code Adapted from AzureAutoGrowShrink.ps1 and Azure-GrowShrinkOnDemand.ps1
#Version 0.0.1
#Keywords: HPC,Azure Paas, Auto grow and Shrink, Calls
#Comments:This module provides tools to enable autoscaling an HPC Server 2012 R2 Environment 
#-------------------------------------------------------------------------------

Function GetLogFileName{
<#
    .Synopsis
    This determines the location of the log file
    
    .Parameter LogFilePrefix
    The Prefix before the dated name
    
    .Example
    GetLogFileName -TEST
    
    .Notes
    
    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param (
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix
    )
    $datetimestr = (Get-Date).ToString("yyyyMMdd")        
    Write-Output [string]::Format("{0}_{1}.log", $LogFilePrefix, $datetimestr)
}

Function LogInfo{
<#
    .Synopsis
    This Logs an INFO level line

    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter Message
    The string containing the information
    
    .Example
    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "5 things happened"
    
    .Notes
    Used throughout

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$False)]
    [string]
    $message
    )

    $LogDate=Get-Date -Format 'yyyy/MM/dd HH:mm:ss'
    $Path = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
    $message = "$LogDate [Info] Component:$Path Status:Online $message"

    if($Logging -eq $true){
        Write-Verbose $message
        $message >> $(GetLogFileName -LogFilePrefix $LogFilePrefix)
    }
  
    else{
    Write-Host $message
    }
}

Function LogWarning{
<#
    .Synopsis
    This Logs an WARNING level line
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    .Parameter Message
    The string containing the information
    
    .Example
    LogWarning -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "5 things happened"
    
    .Notes
    Used throughout

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False)]
    [String]
    $message
    )

    $LogDate=Get-Date -Format 'yyyy/MM/dd HH:mm:ss'
    $Path = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
    $message = "$LogDate [Warning] Component:$Path Status:Online $message"

    if($Logging -eq $true){
        Write-Warning $message
        $message >> $(GetLogFileName -LogFilePrefix $LogFilePrefix)
    }
    else{
        Write-Host -ForegroundColor Yellow $message
    }
}

Function LogError{
<#
    .Synopsis
    This Logs an ERROR level line

    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Message
    The string containing the information
    
    .Example
    LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    
    .Notes
    Used throughout

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False)]
    [string[]]
    $message
    )

    $LogDate=Get-Date -Format 'yyyy/MM/dd HH:mm:ss'
    $Path = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
    $message = "$LogDate [Error] Component:$Path Status:Online $message"

    if($Logging -eq $true){
        Write-Error $message
        $message >> $(GetLogFileName -LogFilePrefix $LogFilePrefix)
        $error.Clear()
    }
    else{
        Write-Host -ForegroundColor Red $message
        $error.Clear()
    }
}

Function ActiveJobCount{
<#
    .Synopsis
    This counts how many Jobs are active on the grid at the current time. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Example
    ActiveJobCount
    
    .Notes
    Used as a shortcut check, If 0, no need to continue.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False
    )

    Try{
        $Source = Get-HpcClusterOverview -verbose
        $Count += $Source.QueuedJobCount
        $Count += $Source.RunningJobCount
        write-output $Count
        }
    Catch [System.Exception]{
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }
}

Function ActiveJobs{

<#
    .Synopsis
    This collects all running and queued HPC Job Objects.
     
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
        
    .Parameter jobTemplates
    Used to limit the search to a specific Job Template Name 
      
    .Parameter JobState
    Used to determine which Jobs should be included. Defaults to running and queued. 
    
    .Example
    ActiveJobs -Jobstate queued -jobTemplates Default_Job_Template
    
    .Notes
    Used as a shortcut to collect Job Objects.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $jobTemplates,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $JobState = @("Running,Queued")
    )

    Try{
        
        $Count = ActiveJobCount
        If($Count -gt 0){
            $activeJobs = @()
            if ($JobTemplates.Count -ne 0){
                foreach ($jobTemplate in $JobTemplates){
                    $activeJobs += @(Get-HpcJob -State $JobState -TemplateName $jobTemplate -ErrorAction SilentlyContinue -verbose)
                    }
            }
            else{
                    $activeJobs = @(Get-HpcJob -State $JobState -ErrorAction SilentlyContinue -verbose)
                }
        }
    }
    
    Catch [System.Exception]{
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }
    Write-Output $ActiveJobs

}

Function MaintainOneNodePerGroup{
<#
    .Synopsis
    This ensures at least one Node is running for each Group. Defaults to ComputeNodes only.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter NodeGroup
    Determines which Nodes will be kept alive, if blank any. Defaults to ComputeNodes

    .Parameter ExcludedGroups
    Determines which groups are NOT discriminated on. Defaults to AzureNodes,ComputeNodes

    .Parameter ExcludedNodes
    Determines which Nodes are not touched

    .Example
    MaintainOneNodePerGroup -Logging $False -NodeGroup AzureNodes,ComputeNodes -ExcludedGroups Group1
    
    .Notes
    Used to ensure a job will always start.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $NodeGroup = @("ComputeNodes"),

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @("ComputeNodes,AzureNodes,InternalCloudNodes")
    )

    Try{

    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING"
    $ExcludedArray = $ExcludedGroups.Split(",")
    $MoreThanOneNode = $False
    $Workers = Get-HpcNode -GroupName $NodeGroup -State Online,Provisioning -HealthState OK -ErrorAction SilentlyContinue -Verbose
    $Slackers = Get-HpcNode -GroupName $NodeGroup -State Offline -HealthState OK -ErrorAction SilentlyContinue -Verbose

    $Workers = @($Workers | ? { $ExcludedNodes -notcontains $_.NetBiosName}) 
    $Slackers = @($Slackers | ? { $ExcludedNodes -notcontains $_.NetBiosName})
    $Groups = @()
    ForEach($Node in $Workers){
        $Array = $Node.Groups.Split(",")
        forEach($GP in $Array){
            if($Groups -notcontains $GP -and $ExcludedArray-notcontains $GP){
                $Groups += $GP
                }
            if($Groups -contains $GP){
                $MoreThanOneNode = $True
            }
        }
    }
    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:EXCEEDED Groups:`"$Array`""

    ForEach($Node in $Slackers){
        $Array = $Node.Groups.Split(",")
        forEach($GP in $Array){
            if($Groups -notcontains $GP -and $ExcludedArray -notcontains $GP){
                $Groups += $GP
                $Name = $Node.NetBiosName
                LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  " Action:SETONLINE Node:$Name Group:$GP"
                Set-HpcNodeState -State online -Node $Node -Verbose
            }
        }
    }
    
    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETED MoreThanOneNode:$MoreThanOneNode"
    }
    
    Catch [System.Exception]{
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    
    }
}

Function GridWorkload {
<#
    .Synopsis
    This calculates the current load on grid at the current time. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter jobTemplates
    Used to check workload for specific job templates only. 

    .Example
    GridWorkload -jobTemplates Template1 -Logging $False
    
    .Notes
    Used to determine what the current load is - pass it to GrowCheck

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $jobTemplates = @()
    )

    Try {

    $TotalCalls = 0
    $Duration = 0
    $OutstandingCalls = 0
    $RunningCalls = 0
    $CompletedCalls = 0
    $AllocatedCores = 0

    $activeJobs = @()
        if ($JobTemplates.Count -ne 0) {
            foreach ($jobTemplate in $JobTemplates) {
                $activeJobs += @(Get-HpcJob -State Running,Queued -TemplateName $jobTemplate -ErrorAction SilentlyContinue -
                )
            }
        }
        else {
            $activeJobs = @(Get-HpcJob -State Running,Queued -ErrorAction SilentlyContinue -Verbose)
        }
        Write-Verbose "ActiveJobs: $($activeJobs | Out-String)"
    }

    Catch {
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message 
    }

    Try {
        foreach ($job in $activeJobs) {
            Write-Verbose "Job: $($job | Out-String)"
            $Duration += $job.CallDuration
            $TotalCalls += $job.NumberOfCalls
            $OutstandingCalls += $job.OutstandingCalls
            $RunningCalls += $job.CurrentAllocation
            $AllocatedCores += $job.CurrentAllocation
        }

        $AvgSecs = [math]::Round(($Duration / 1000),2)
        $RemainingSecs = ($AvgSecs * $OutstandingCalls)

        if($AllocatedCores -eq 0) {
            $GridRemainingSecs = 0
        }
        else {
            $GridRemainingSecs = [math]::Round(($RemainingSecs / $AllocatedCores),2)
        }

        $GridRemainingMins = [math]::Round(($GridRemainingSecs / 60),2)
        $CompletedCalls = ($TotalCalls - $OutstandingCalls)
        $MSG = "Action:REPORTING Duration:$Duration AvgSecs:$AvgSecs TotalCalls:$TotalCalls OutstandingCalls:$OutstandingCalls CompletedCalls:$CompletedCalls RunningCalls:$RunningCalls AllocatedCores:$AllocatedCores GridRemainingMins:$GridRemainingMins GridRemainingSecs:$GridRemainingSecs"
        Write-Verbose "LOGInfo: $MSG"
        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  $MSG
    }

    Catch {
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message 
    }

    $stats = New-Object -TypeName PSObject -Property @{Duration=$Duration;AvgSecs=$AvgSecs;TotalCalls=$TotalCalls;OutstandingCalls=$OutstandingCalls;CompletedCalls=$CompletedCalls;RunningCalls=$RunningCalls;AllocatedCores=$AllocatedCores;GridRemainingMins=$GridRemainingMins;GridRemainingSecs=$GridRemainingSecs}
    
    Write-Output $stats
}

Function GrowCheck{
<#
    .Synopsis
    This calculates whether the load on the Grid requires more resources. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean wether or not to create a log or just display host output

   .Parameter OutstandingCalls
   Amount of Calls awaiting completion - collected from GridWorkload

   .Parameter activeJobs
    The current Jobs. Use ActiveJobs to create the object required

   .Parameter CallQueueThreshold
    The number of queued calls required to set off a growth of Nodes.Default is 2000

   .Parameter GridRemainingMins
    Minutes of Grid time remaining. Sourced from Grid Workload

   .Parameter NumOfQueuedJobsToGrowThreshold
    The number of queued jobs required to set off a growth of Nodes. The default is 1. For SOA sessions, this should be set to 1 

   .Parameter GridMinsRemainingThreshold
    The time in minutes, of remaining Grid work. If this threshold is exceeded, more Nodes will be allocated. Default is 30

    .Example
    GridWorkload | GrowCheck -Logging $False -CallQueueThreshold 1500
    
    .Notes
    Used as a shortcut check, If 0, no need to continue.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [Microsoft.ComputeCluster.CCPPSH.HpcJob[]]
    $activeJobs,

    [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $OutstandingCalls,

    [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $GridRemainingMins,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $CallQueueThreshold=2000,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $NumOfQueuedJobsToGrowThreshold=1,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $GridMinsRemainingThreshold= 40
    )

    Try{
        $GROW = $False

        if($CallQueueThreshold -ne 0){
    
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "CallQueueThreshold:$CallQueueThreshold CallQueue:$OutstandingCalls"
        }

        if($OutstandingCalls -ge $CallQueueThreshold){
            $GROW = $true
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "CallQueueThreshold Exceeded"
        }

        if($GridMinsRemainingThreshold -ne 0 ){

            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "GridMinsRemainingThreshold:$GridMinsRemainingThreshold GridMinsRemaining:$GridRemainingMins"
        }
        
        if($GridRemainingMins -ge $GridMinsRemainingThreshold){
                $GROW = $true
                LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "GridMinsRemainingThreshold Exceeded"
        }
    
        if($NumOfQueuedJobsToGrowThreshold -ne 0){
    
            $queuedJobs = @($activeJobs | ? { $_.State -eq 'Queued' } )
            $QJobCount = $queuedJobs.Count

            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "QueuedJobsThreshold:$NumOfQueuedJobsToGrowThreshold QueuedJobs:$QJobCount"
        }

        if($queuedJobs.Count -ge $NumOfQueuedJobsToGrowThreshold){
            $GROW = $true
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "QueuedJobsThreshold Exceeded"
            }
    
    }

    Catch [System.Exception]{
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }

    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE GrowState:$GROW"

    Write-Output $Grow
}

Function ClusterStatus{
<#
    .Synopsis
    This Write-Outputs the current status of the Grid in the form of an object, to determine which Groups, Pools and Templates are currently required.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Example
    ClusterStatus -Logging $False -ExcludedGroups SlowNodes
        
    .Notes
    Used to determine which resources can be reassigned

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @("InternalCloudNodes")
    )

    Try{
    $JobCount = ActiveJobCount -LogFilePrefix $LogFilePrefix -Logging $Logging
    $Jobs = ActiveJobs -LogFilePrefix $LogFilePrefix -Logging $Logging -JobState Running
    $Groups = @()
    $JobTemplates = @()
    $NodeTemplates = @()
    $BusyNodes = @()
    $BusyPools = @()
    $AvailableNodes = @()
    $IdleGroups = @()
    $IdlePools = @()
    $IdleCores = 0
    $BusyCores = 0
    $ExcludedCores = 0
    $IdleNodes = @()
    $IdleJobTemplates = @()
    $IdleNodeTemplates = @()
    $NodeMasterList = Get-HpcNode -HealthState OK
    $GroupMasterList = Get-HpcGroup
    $PoolMasterList = Get-HpcPool
    $NodeTemplateMasterList = Get-HpcNodeTemplate
    $JobTemplateMasterList = Get-HpcJobTemplate
    $MappedNodeTemplates = @{}


    forEach($Group in $GroupMasterList){
        if($Group.Id -lt 10){
            $ExcludedGroups += $Group.Name
        }
    }

    If($JobCount -ne 0){

        ForEach($Job in $Jobs){
            $BusyNodes += $Job.AllocatedNodes.Split(",")
            if($BusyPools -notcontains $Job.pool){
                $BusyPools += $Job.pool
                }
            if($JobTemplates -notcontains $Job.Template){
                $JobTemplates += $Job.Template
                }
            $BusyCores += $Job.CurrentAllocation
        }
        If($BusyNodes.Count -ne 0){
            $NodeObj = Get-HpcNode -Name $BusyNodes.split(",")

            ForEach($IT in $NodeObj){
                If($ExcludedNodes -notcontains $IT.NetBiosName){
                    If($NodeTemplates -notcontains $IT.Template){
                        $NodeTemplates += $IT.Template
                    }
                $Array = $IT.Groups.split(",")    
                    forEach($GP in $Array){
                            if($Groups -notcontains $GP -and $ExcludedGroups -notcontains $GP){
                            $Groups += $GP
                            }
                        }
                    }
                }
            }
        }

    forEach($Group in $GroupMasterList){
        if($Group.Id -gt 09 -and $Groups -notcontains $Group.Name){
            $IdleGroups += $Group.Name
            }
        }

    forEach($Pool in $PoolMasterList){
        if($BusyPools -notcontains $Pool.Name){
            $IdlePools += $Pool.Name
            }
        }

    forEach($JTemp in $JobTemplateMasterList){
        if($JobTemplates -notcontains $JTemp.Name){
            $IdleJobTemplates += $JTemp.Name
            }
        }

    forEach($Template in $NodeTemplateMasterList){
        if($NodeTemplates -notcontains $Template.Name -and $Template.Name -notContains "HeadNode","Broker" -and $ExcludedNodeTemplates -notcontains $Template.Name){
            $IdleNodeTemplates += $Template.Name
            }
        if($NodeTemplates -notcontains $Template.Name -and $Template.Name -Contains "HeadNode","Broker"){
            $ExcludedNodeTemplates += $Template.Name
            }
        }

    forEach($Node in $NodeMasterList){
        if($BusyNodes -notcontains $Node.NetBiosName -and $Node.NodeRole -notContains "BrokerNode" -and $ExcludedNodes -notcontains $Node.NetBiosName){
            $IdleNodes+= $Node.NetBiosName
            $IdleCores += $Node.ProcessorCores
            }
        elseif($Node.NodeRole -Contains "BrokerNode"){
            $ExcludedNodes += $Node.NetBiosName
            $ExcludedCores += $Node.ProcessorCores
            }
        elseif($ExlcudedNodes -Contains $Node.NetBiosName){
            $ExcludedNodes += $Node.NetBiosName
            $ExcludedCores += $Node.ProcessorCores
            }
        }

        $Obj = New-Object psobject -Property @{BusyGroups=$Groups;ExcludedGroups=$ExcludedGroups;IdleGroups=$IdleGroups;BusyPools=$BusyPools;IdlePools=$IdlePools;BusyNodes=$BusyNodes;IdleNodes=$IdleNodes;ExcludedNodes=$ExcludedNodes;BusyJobTemplates=$JobTemplates;IdleJobTemplates=$IdleJobTemplates;BusyNodeTemplates=$NodeTemplates;IdleNodeTemplates=$IdleNodeTemplates;BusyCores=$BusyCores;IdleCores=$IdleCores;ExcludedCores=$ExcludedCores}
        Write-Output $Obj
        }

    Catch [System.Exception]{
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        $Error.Clear()
    
    }
}

Function MapJobAndNodeTemplates{
<#
    .Synopsis
    This collects the default Node Template for each Job Template - later used for re-assigning ComputeNodes.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered 

    .Example
    MapJobAndNodeTemplates -Logging $False -ExcludedNodeTemplates -TestNodeTemplate
        
    .Notes
    Used to discover which template to apply.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @()
    )
    Try{
    $JobNodeTemplateMap = @{}
    $Status= ClusterStatus
    $TempGroupMap = ExtractDefaultGroupFromTemplate

    Foreach($JTemp in $Status.BusyJobTemplates){
            $MappedYet = @()

            if($ExcludedNodeTemplates -ne 0){
                $MappedYet = $ExcludedNodeTemplates
            }

            Foreach($Node in $Status.BusyNodes){
                $it = Get-HpcNode -Name $Node -GroupName $TempGroupMap.Item($JTemp) -ErrorAction SilentlyContinue

                If($MappedYet -notcontains $it.Template){
                            If($it.Template -ne $null){
                    $MappedYet += $it.Template
                    }
                    }

            }

            $JobNodeTemplateMap += @{$Jtemp=$MappedYet}
        }

        Write-Output $JobNodeTemplateMap
        }
        Catch [System.Exception]{
            LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
            $Error.clear()
        }
}

Function ExtractDefaultGroupFromTemplate{
<#
    .Synopsis
    This extracts the default Group for a Job Template. Can Take either one template or generate a hash table for all 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter Templates
    You can specify which Job Template to analyse, otherwise it will just get them all. 

    .Example
    ExtractDefaultGroupFromTemplate -Logging $False -Templates JobTemplate1,JobTemplate2
    
    .Notes
    Used to ensure the right groups are assigned later.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [Microsoft.ComputeCluster.CCPPSH.HpcJobTemplate[]] 
    $Templates = @()
    )

    Try{
    $TemplateMap = @{}

    If($Templates.Count -eq 0){
        $Templates = Get-HpcJobTemplate
        }

    foreach($Template in $Templates){
        Export-HpcJobTemplate -Template $Template -Path .\temp.xml -Force -ErrorAction SilentlyContinue
        [xml]$XML = Get-Content .\temp.xml 
    
        $Source = $XML.JobTemplate.TemplateItem
            forEach($Item in $Source){
                If($Item.PropertyName -eq "NodeGroups"){
                    $DEFAULTGROUP = $Item.Default
                    $TemplateMap +=@{$Template.Name=$DEFAULTGROUP}
                }
            }
    }
    Remove-Item .\temp.xml

    Write-Output $TemplateMap
    }
    Catch [System.Exception]{
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }

}

Function TemplateSwap{
<#
    .Synopsis
    This swaps offline Nodes to templates currently in demand. It assumes that the groups are being used as discriminators and that the Nodes have already had their groups stripped. Designed for ComputeNodes rather than AzureNodes (will not take UnDeployed Nodes). 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter NodesToGrow
    A collection of Nodes you want to grow. Should be recieved from StripGroups if using groups as discriminators. 

    .Example
    IdleDifferentNodes | StripGroups | TemplateSwap
    
    .Notes
    Once given a collection of Nodes, will discover which groups need assigning and assign them.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $LogFilePrefix,

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [bool] 
        $Logging=$False,

        [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
        [Microsoft.ComputeCluster.CCPPSH.HpcNode[]]
        $NodesToGrow = @()
        )
        
        Try{

        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING "   
        $SUCCESS = $False
        $Status = ClusterStatus
        $Ratio = 1

        If($NodesToGrow.Count -ne 0){
            ForEach($Node in $NodesToGrow){
                $CoresToGrow += $Node.ProcessorCores
            }
   
            if($Status.BusyNodeTemplates.Count -gt 1){
            $Ratio = [math]::Round((1/$Status.BusyNodeTemplates.Count),2)
            }

            $NodeNames = $NodesToGrow.NetBiosName
            $TempName =  $Status.BusyNodeTemplates
            $NodeTempObjs = Get-HpcNodeTemplate -Name $Status.BusyNodeTemplates
            $JobTempObjs = Get-HpcJobTemplate -Name $Status.BusyJobTemplates
            $TemplateMap = ExtractDefaultGroupFromTemplate -Templates $JobTempObjs
            $NodeJobMap = MapJobAndNodeTemplates

            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:CALCULATING Ratio:$Ratio"

            Set-HpcNodeState -Node $NodesToGrow -State offline -Force -errorAction SilentlyContinue

            $SortedNodes = $NodesToGrow | Sort-Object NodeState,ProcessorCores,Memory
            $NodesPerTemplate = [math]::Floor([decimal]($NodesToGrow.Count * $Ratio))

            If($Ratio -eq 1){

                    $NodeTempName = $NodeTempObjs.Name
                    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:SINGLETEMPLATECHANGE JobTemplate:$TempName  NodeTemplate:$NodeTempName Nodes:$NodeNames"
                    Assign-HpcNodeTemplate -Template $NodeTempObjs -Node $NodesToGrow -Confirm:$false
                
                    $TemplateMap.GetEnumerator() | % {
                        $GroupToAssign = $($_.Value)   
                        }

                    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:GROUPASSIGN AssignGroups:$GroupToAssign AssignedTo:$NodeNames"
                    Add-HpcGroup -Name $GroupToAssign -Node $NodesToGrow
                    Set-HpcNodeState -Node $NodesToGrow -State online
                }

            Else{
                    $NodeAssigned = @()
                    $CoresPerTemplate = ($CoresToGrow * $Ratio)

                    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:MULTITEMPLATECHANGE Templates:$TempName  Nodes:$NodeNames CoresPerTemplate:$CoresPerTemplate"
                
                    Foreach($JTemplate in $JobTempObjs){
                    
                        $NodeToAssign = @()
                        $AssginedNames = @()
                        $CoresAssigned = 0
                        $NodeTempToSet = $NodeJobMap.Item($JTemplate.Name)
                        $JobTemplateName = $JTemplate.Name
                        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:TEMPLATEASSIGN JobTemplate:$JobTemplateName  NodeTemplate:$NodeTempToSet MaxCoresPerTemplate:$CoresPerTemplate"
                    
                        ForEach($Node in $NodesToGrow){
                            If($NodeAssigned -notcontains $Node.NetBiosName){
                                If($CoresAssigned -lt $CoresPerTemplate){
                                    $NodeAssigned += $Node.NetBiosName 
                                    $AssignedNames += $Node.NetBiosName 
                                    $NodeToAssign += $Node
                                    $CoresAssigned += $Node.ProcessorCores
                                }
                            }

                        }
                        If($NodeToAssign.Count -ne 0){
                            $NodeObjToSet = Get-HpcNodeTemplate -Name $NodeTempToSet
                            $NodesWithWrongTemplates = @()
                            ForEach($Node in $NodeToAssign){
                                $ITName = $Node.NetBiosName
                                If($Node.Template -eq $NodeObjToSet.Name){
                                    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:TEMPLATEASSIGN JobTemplate:$JobTemplateName Node:$ITName NodeTemplate:$NodeTempToSet Msg:`"Template already correct`""
                                }
                                Else{
                                    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:TEMPLATEASSIGN JobTemplate:$JobTemplateName Node:$ITName NodeTemplate:$NodeTempToSet  Msg:`"Template needs changing`""
                                    $NodesWithWrongTemplates += $Node
                                }
                            }
                            If($NodesWithWrongTemplates.Count -ne 0){
                                LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:TEMPLATEASSIGN JobTemplate:$JobTemplateName Node:$ITName NodeTemplate:$NodeTempToSet Nodes:$AssignedNames MaxCoresPerTemplate:$CoresPerTemplate"
                                Assign-HpcNodeTemplate -Template $NodeObjToSet -Node $NodesWithWrongTemplates -Confirm:$false
                            }

                            $GroupToAssign = $TemplateMap.Item($JobTemplateName)

                            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:GROUPASSIGN AssignGroups:$GroupToAssign AssignedTo:$AssignedNames"
                            Add-HpcGroup -Name $GroupToAssign -Node $NodeToAssign
                            Set-HpcNodeState -Node $NodeToAssign -State online
                        }
                    }
                }

            
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE"
            $Success = $True
            Write-Output $SUCCESS 
            }

        Else{
             LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:NOTHING Msg:`"No Nodes available for Template Swap`""
             Write-Output $SUCCESS
            }
            
        }
        Catch{
            LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
            $Error.Clear()
            Write-Output $SUCCESS
        }
}

Function NodeGrowth{
<#
    .Synopsis
    This takes a list of nodes and grows them according to the scaling parameters given. Works with Azure AND ComputeNodes  
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter NodesToGrow
    A collection of Nodes you want to grow. If none is provided, will assume all nodes want to grow.

    .Parameter ExcludedNodes
    Nodes you do not want touched.
     
    .Parameter $NodeGroup
    Which Nodes can be grown. Defaults to AzureNodes AND ComputeNodes. If you only want to grow one type, select this. 
    
    .Parameter NodeTemplates
    Used to specify growing only a certain type of Nodes. 

    .Parameter InitialNodeGrowth
    If less than 1 Node alive, how many should be grown. Default is 10.

    .Parameter NodeGrowth
    Assuming more than 1 node currently exists (i.e. the Grid is currently running) how much more should be assigned.

    .Example
    To autoscale your Azure Nodes up: NodeGrowth -NodeGroup AzureNodes
    
    .Notes
    Scales the grid up as and when required. If you have an agnostic Grid (all services can run on all nodes) this will be sufficient - if you have more complex needs you can pass the Nodes as NodesToGrow and scale up gradually.

    .Link
    www.excelian.com
#>
    Param(
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $LogFilePrefix,

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [bool] 
        $Logging=$False,

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $NodeGroup="AzureNodes,ComputeNodes",

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $ExcludedNodes=@(),


        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $NodeTemplates,

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [int] 
        $InitialNodeGrowth=10,

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [int] 
        $NodeGrowth=5,

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [Microsoft.ComputeCluster.CCPPSH.HpcNode[]]
        $NodesToGrow= @()
    )


    Try{
        $GrowthSuccess = $False

        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING"
        
        if($NodesToGrow.Count -eq 0){

            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:CALCULATING"
        
            $azureNodes = @();

            #Collect group of available Nodes
            if ($NodeTemplates.Count -ne 0){
                    $azureNodes = @(Get-HpcNode -GroupName $NodeGroup.split(",") -TemplateName $NodeTemplates -HealthState Ok -ErrorAction SilentlyContinue -Verbose) 
                }
        
            else{
                    $azureNodes = @(Get-HpcNode -GroupName $NodeGroup.split(",") -ErrorAction SilentlyContinue -HealthState OK -Verbose)
                }
            }
        
        else{
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:NODESGIVEN"
            $azureNodes = $NodesToGrow
        }
        $azureNodes = @($azureNodes | ? { $ExcludedNodes -notcontains $_.NetBiosName})

        $targetAZNodes = @();
        $onlineAZNodes = @();

        #Find nodes not yet online or deployed
        forEach($node in $azureNodes){
            if($node.NodeState -eq "NotDeployed" -or $node.NodeState -eq "Offline"){
                $targetAZNodes += $node
                }
            if($node.NodeState -eq "Online" -or $node.NodeState -eq "Provisioning"){
                $onlineAZNodes += $node
                }
            }

        $NodesActive = $False
        $GrowNumber = $InitialNodeGrowth
        
        #Check to see if there are any nodes currently online
        if($onlineAZNodes.Count -gt 0){
            $NodesActive = $True
            $GrowNumber = $NodeGrowth
            }

        $SortedTarget = $targetAZNodes | Sort-Object NodeState,ProcessorCores,Memory
        $UndeployedTargetNodes = @()
        $OfflineTargetNodes = @()

        if($targetAZNodes.Count -gt 0){
                forEach($target in $SortedTarget[0..($GrowNumber - 1)]){
                    $TName = $target.NetBiosName
                    if($target.NodeState -eq "NotDeployed"){
                        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Node:$TName State:NotDeployed Action:DEPLOYING"
                        $UndeployedTargetNodes += $target
                    }
                    elseif($target.NodeState -eq "Offline"){
                        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Node:$TName State:Offline Action:SETONLINE"
                        $OfflineTargetNodes += $target
                        }
                    }

                #First, switch offline nodes online, then deploy new nodes
                if($OfflineTargetNodes.Count -ne 0){
                    If($Logging -eq $true){
                        Set-HpcNodeState -State online -Node $OfflineTargetNodes -ErrorAction SilentlyContinue -Verbose  *>> $(GetLogFileName -LogFilePrefix $LogFilePrefix)  
                        }
                    Else{
                        Set-HpcNodeState -State online -Node $OfflineTargetNodes -ErrorAction SilentlyContinue -Verbose 
                    }
                    }

                if($UndeployedTargetNodes.Count -ne 0){
                        If($Logging -eq $true){
                            Start-HpcAzureNode -Node $UndeployedTargetNodes -Async $false -ErrorAction SilentlyContinue -Verbose *>> $(GetLogFileName -LogFilePrefix $LogFilePrefix)   
                            Set-HpcNodeState -State online -Node $UndeployedTargetNodes -ErrorAction SilentlyContinue -Verbose  *>> $(GetLogFileName -LogFilePrefix $LogFilePrefix)  
                        }
                        Else{
                            Start-HpcAzureNode -Node $UndeployedTargetNodes -Async $false -ErrorAction SilentlyContinue -Verbose
                            Set-HpcNodeState -State online -Node $UndeployedTargetNodes -ErrorAction SilentlyContinue -Verbose                          
                    }
                }
                $GrowthSuccess = $True
            }

        else{
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:NOTHING GrowthSuccess:$GrowthSuccess Msg`"Grid at full capacity`""
            }
        
        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE GrowthSuccess:$GrowthSuccess Msg`"Node Growth Complete`""
        Write-Output $GrowthSuccess
    }
    
    Catch [System.Exception]{
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }

}

Function ShrinkCheck{
<#
    .Synopsis
    This determines whether shrinking is needed - looks for Nodes with no active jobs.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter NodeGroup
    Which Nodes can be shrunk. Defaults to AzureNodes AND ComputeNodes. If you only want to shrink one type, select this. 
    
    .Parameter NodeTemplates
    Used to specify shrinking only a certain type of Nodes. 

    .Parameter ExcludedNodes 
    Node names that must not be considered

    .Example
    ShrinkCheck -NodeGroup AzureNodes
    
    .Notes
    Checks whether there are idle nodes. Write-Outputs SHRINK - boolean to determine to shrink or not, as well as the list of nodes and the objects. 

    .Link
    www.excelian.com
#>

    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $NodeGroup=@("AzureNodes,ComputeNodes"),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @(),

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $NodeTemplates
    )

    Try{
    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING"
    $NodesAvailable = @();
    $State = ClusterStatus -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups

     if ($NodeTemplates.Count -ne 0){
            $NodesAvailable = @(Get-HpcNode -GroupName $NodeGroup.split(",") -Name $State.IdleNodes -State Online -TemplateName $NodeTemplates -ErrorAction SilentlyContinue -Verbose)  
        }

        else{
            $NodesAvailable = @(Get-HpcNode -GroupName $NodeGroup.split(",") -Name $State.IdleNodes -ErrorAction SilentlyContinue -State Online -Verbose)
        }

        # remove head node if in the list
     if ($NodeGroup -eq $NodeGroup.ComputeNodes){
            $NodesAvailable = @($NodesAvailable | ? { -not $_.IsHeadNode })
        }

        $idleNodes = @();
        $NodesList = @();

        foreach ($node in $NodesAvailable){
            $jobCount = (Get-HpcJob -NodeName $node.NetBiosName -ErrorAction SilentlyContinue -Verbose).Count;
            if ($jobCount -eq 0){
                $idleNodes += $node;
                $NodesList += $node.NetBiosName
            }
        }

        if ($idleNodes.Count -ne 0){
            $SHRINK = $true
        }

        else{
            $SHRINK = $false
            }

        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE ShrinkState:$SHRINK"
        }

    Catch [System.Exception]{
    
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        }

    $Checked = New-Object -TypeName PSObject -Property @{SHRINK=$SHRINK;IdleNodes=$idleNodes;NodesList=$NodesList;}
    Write-Output $Checked
}

Function NodeOffline{
<#
    .Synopsis
    This sets the Nodes provided by Shrink Check offline. It does NOT set AzureNodes to Undeployed. Use for balancing as well. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter $idlenodes
    Nodes objects to set offline. Pipeline from ShrinkCheck 
    
    .Parameter Nodeslist
    List of the Node names for logging. ShrinkCheck provides this, if you send your own group then leave blank and it will be filled in. 

    .Parameter SHRINK
    Boolean, if True it will shrink the Nodes. If output piped from ShrinkCheck, will determine whether or not Nodes should be set offline

    .Example
    ShrinkCheck | NodeOffline -Logging $False
    
    .Notes
    Turns Nodes offline only, does not undeploy AzureNodes. 

    .Link
    www.excelian.com
#>
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [Microsoft.ComputeCluster.CCPPSH.HpcNode[]] 
    $idlenodes,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $Nodeslist,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $SHRINK=$True

    )

    Try{
        $OfflineSuccess = $False

        If($SHRINK -eq $True){
            If($Nodeslist.count -eq 0){
                ForEach($Node in $idlenodes){
                    $Nodeslist += $Node.NetBiosName
                }
            }

            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING NodeCount:$($idleNodes.Count) Nodes:`"$NodesList`""
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:OFFLINE Msg:`"Bringing nodes offline`""
            If($Logging -eq $True){
                Set-HpcNodeState -Node $idleNodes -State offline -WarningAction Ignore -ErrorAction SilentlyContinue -Verbose *>> $(GetLogFileName -LogFilePrefix $LogFilePrefix)   
            }
            Else{
                Set-HpcNodeState -Node $idleNodes -State offline -WarningAction Ignore -ErrorAction SilentlyContinue -Verbose
            }
            
            $error.Clear();

            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE Msg:`"Nodes offline`""
                
            $ShrinkCheck = 0
            $OfflineSuccess = $True
        }
        Else{
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "Action:COMPLETE Msg:`"No Nodes to Shrink`""
        }
    }

    Catch [System.Exception] {
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        }
        Write-Output $OfflineSuccess

}

Function NodeShrink{
<#
    .Synopsis
    This shrinks the Nodes provided by Shrink Check - setting ComputeNodes offline and Undeploying AzureNodes. It means redeploying the Azure Nodes will take longer. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter $idlenodes
    Nodes objects to shrink. Pipeline from ShrinkCheck 
    
    .Parameter Nodeslist
    List of the Node names for logging. ShrinkCheck provides this, if you send your own group then leave blank and it will be filled in. 

    .Parameter SHRINK
    Boolean, if True it will shrink the Nodes. If output piped from ShrinkCheck, will determine whether or not Nodes should be shrunk

    .Example
    ShrinkCheck | NodeShrink -Logging $False
    
    .Notes
    Turns ComputeNodes offline and AzureNodes undeployed. 

    .Link
    www.excelian.com
#>

    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [Microsoft.ComputeCluster.CCPPSH.HpcNode[]] 
    $idlenodes,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $Nodeslist = @(),

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $SHRINK=$True
    )

    Try{
        $ShrinkSuccess = $false
        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:STARTING NodeCount:$($idleNodes.Count) Nodes:`"$NodesList`""

        If($SHRINK -eq $True){
            If($Nodeslist.count -eq 0){
                ForEach($Node in $idlenodes){
                    $Nodeslist += $Node.NetBiosName
                }
            }
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:OFFLINE Msg:`"Bringing nodes offline`""
        
            If($Logging -eq $True){
                Set-HpcNodeState -Node $idleNodes -State offline -WarningAction Ignore -ErrorAction SilentlyContinue -Verbose *>> $(GetLogFileName -LogFilePrefix $LogFilePrefix)   
            
                $error.Clear();

                LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:NOTDEPLOYED Msg:`"Setting Nodes to Not Deployed`""

                Stop-HpcAzureNode -Node $idleNodes -Force $false -Async $false -ErrorAction SilentlyContinue *>> $(GetLogFileName -LogFilePrefix $LogFilePrefix)   
            }

            Else{
                Set-HpcNodeState -Node $idleNodes -State offline -WarningAction Ignore -ErrorAction SilentlyContinue -Verbose 
            
                $error.Clear();

                LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:NOTDEPLOYED Msg:`"Setting Nodes to Not Deployed`""

                Stop-HpcAzureNode -Node $idleNodes -Force $false -Async $false -ErrorAction SilentlyContinue
            }

                if (-not $?){
                    LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Stop Azure nodes failed."
                    LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
                    $ShrinkSuccess = $false
                    }
                
                else{
                    LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:COMPLETE Msg:`"Nodes offline`""
                    $ShrinkSuccess = $true
                    }
                $ShrinkCheck = 0
        }
        Else{
            LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:COMPLETE Msg:`"No Nodes switched offline`""
        }
        
            Write-Output $ShrinkSuccess
        }

    Catch [System.Exception] {
        LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        }

}

Function IdleReadyNodesAvailable{
<#
    .Synopsis
    This Write-Outputs a boolean, determining whether there are nodes that can be simply switched online. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Example
    IdleReadyNodesAvailable -ExcludedNodes BATTLESTAR
    
    .Notes
    Checks to see if there are Nodes currently workth Growing

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @("InternalCloudNodes,ComputeNodes,AzureNodes")
    )

    $State = ClusterStatus -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes
    $NodesAvailable = $False

    If($State.BusyGroups.Count -ne 0 -and $State.IdleNodes.Count -ne 0){
        $NodesToGrow = Get-HpcNode -Name $State.IdleNodes -GroupName $State.BusyGroups -State Offline,NotDeployed -HealthState OK -ErrorAction SilentlyContinue 

        If($NodesToGrow.Count -ne 0){
                $NodesAvailable = $True
                }
        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETED NodesAvailable:$NodesAvailable"
        Write-Output $NodesAvailable
    }
    Else{
         LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETED NodesAvailable:$NodesAvailable"
         Write-Output $NodesAvailable
    }
}

Function IdleReadyNodes{
<#
    .Synopsis
    This Write-Outputs Node Objects, for nodes that can be simply switched online. Pipe this to NodeGrowth
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Example
    IdleReadyNodes -ExcludedNodes BATTLESTAR
    
    .Notes
    Provides Node Objects that match currently running criteria.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @("InternalCloudNodes,ComputeNodes,AzureNodes")
    )

    $NodesToGrow = @()
    $State = ClusterStatus -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes
    If($State.BusyGroups.Count -ne 0 -and $State.IdleNodes.Count -ne 0){
        $NodesToGrow = Get-HpcNode -Name $State.IdleNodes -GroupName $State.BusyGroups -State Offline,NotDeployed -HealthState OK -ErrorAction SilentlyContinue
    }
    Write-Output $NodesToGrow
}

Function IdleDifferentNodesAvailable{
<#
    .Synopsis
    This Write-Outputs a boolean, determining whether there are nodes that can have their template switched. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter NodeGroup
    Determines which Groups should be looked at. Defaults to ComputeNodes (ie All on premises nodes) as you wouldn't often want to swap an AzureNodes Template

    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    If you have descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Example
    IdleDifferentAvailable
    
    .Notes
    Checks to see if there are Nodes that can have their template switched

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @(),


    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $NodeGroup = @("ComputeNodes")
    )

        $IT = IdleDifferentNodes -LogFilePrefix $LogFilePrefix -Logging $Logging -NodeGroup $NodeGroup -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups
        
        If($IT.Count -ne 0){
            $NodesAvailable = $True
        }
        Else{
            $NodesAvailable = $False
        }

        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:Completed NodesAvailable:$NodesAvailable"

        Write-Output $NodesAvailable
}

Function IdleDifferentNodes{
<#
    .Synopsis
    This Write-Outputs Node Objects,for nodes that can have their template switched. Pipe this to Strip Groups if using discriminators, NodeGrowth if not.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as active/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Parameter NodeGrowth
    The amount of Nodes to grow by - defaults to 5

    .Parameter NodeGroup
    Determines which Groups should be looked at. Defaults to ComputeNodes (ie All on premises nodes) as you wouldn't often want to swap an AzureNodes Template

    .Example
    IdleDifferentNodes -NodeGroup ComputeNodes,AzureNodes | StripGroups | TemplateSwap
    
    .Notes
    Provides Nodes that can have their template switched

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $NodeGroup = @("ComputeNodes"),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [int] 
    $NodeGrowth=5,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @()

    )

    $State = ClusterStatus -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups

    If($State.IdleNodes.Count -ne 0){
        $NodesAvailable = Get-HpcNode -Name $State.IdleNodes -GroupName $NodeGroup -HealthState OK -ErrorAction SilentlyContinue | Sort-Object -Property ProcessorCores,Memory -Descending
        $UniqueGroups = @()
        $UnqiueNodes = @()
        $NodesToGrow = @()
    
        ForEach($Node in $NodesAvailable){
            $Array = $Node.Groups.split(",") 
                forEach($GP in $Array){
                    if($UniqueGroups -notcontains $GP -and $NodeGroup -notcontains $GP){
                        $UniqueGroups += $GP
                        $UniqueNodes += $Node.NetBiosName + ","
                    }
                }
        }
        $NodesToGrow = @($NodesAvailable | ? {$UniqueNodes.Split(",") -notcontains $_.NetBiosName }) 
        Write-Output $NodesToGrow[0..($NodeGrowth - 1)] 
    }
    else{
        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Msg`"No Nodes Available`""
    }
}

Function StripGroups{
<#
    .Synopsis
    This strips the groups (excluding system groups 1-9) from a Template, so the template can be switched and a new discriminator applied. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter NodesToGrow
    A collection of Nodes you want to strip.

    .Parameter ExcludedGroups
    If you have a group that you want to leave assigned, excluded groups will stop it from being stripped.

    .Example
    IdleDifferentNodes -NodeGroup ComputeNodes,AzureNodes | StripGroups -ExcludedGroups Group1,Group2 | TemplateSwap
    
    .Notes
    Strips Nodes of their groups ready for re-assignment. 

    .Link
    www.excelian.com
#>
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $LogFilePrefix,

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [bool] 
        $Logging=$False,

        [Parameter (Mandatory=$True,ValueFromPipeline=$True)]
        [Microsoft.ComputeCluster.CCPPSH.HpcNode[]]
        $NodesToGrow = @(),

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $ExcludedGroups = @()

        )

        Try{

        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING"

        $ALL = Get-HpcGroup |? {$_.ID -gt 9}
       
        $ToStrip = @()


        $Status = ClusterStatus -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedGroups $ExcludedGroups
        ForEach($Group in $All){
            If($Status.ExcludedGroups -notcontains $Group.Name){
               $ToStrip += $Group.Name
            }
        }

        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:REMOVING GROUPS:$ToStrip"

        Set-HpcNodeState -Node $NodesToGrow -State offline -Force -errorAction SilentlyContinue
        Remove-HpcGroup -Name $ToStrip -Node $NodesToGrow -Confirm:$false

        LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETED"
        #Write-Output $NodesToGrow
        }
        Catch{
            LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        }
}

Function NodeBalance{
<#
    .Synopsis
    This determines whether the Grid is currently evenly balanced.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter PercentageTolerance
    How much percentage over or under the perfect balance percentage before the Grid is deemed unbalanced. If not provided, 

    .Parameter ExcludedNodeTemplates
    Determines which Node templates will be excluded from the calculation

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Example
    NodeBalance -Logging $False -ExcludedGroups SlowNodes
        
    .Notes
    Used to determine which resources can be reassigned

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LogFilePrefix,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [int]
    $PercentageTolerance = 15,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @("InternalCloudNodes")
    )

    Try{
        $JCount = ActiveJobCount -LogFilePrefix $LogFilePrefix -Logging $Logging
        $Balanced = $True
        If($JCount -ne 0){
            $State = ClusterStatus -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups

            If($State.BusyNodeTemplates.Count -gt 1){
                $NodeTemplateChecked = @()
                $NodesForBalancing = @()
                $TemplateNodeMap = @{}
                $TemplateCoreMap = @{}
                $NodeNameMap = @{}
                $CoresCanMove = 0
                $TotalNodes = 0
                $TotalCores = 0
                $BusyTempCount = $State.BusyNodeTemplates.Split(",").Count
                $BusyNodeCount = $State.BusyNodes.Split(",").Count
                $NodesCanMoveCount = $BusyNodeCount - $BusyTempCount
                $NodesCanMove = @()
                $NodesBalanced = $True
                $CoresBalanced = $True
            
                $Nodes = Get-HpcNode -Name $State.BusyNodes.split(",") | sort -Property ProcessorCores -Descending

                ForEach($Node in $Nodes){
                    
                    $TotalCores += $Node.ProcessorCores
                    $TotalNodes += 1

                    If($NodeTemplateChecked -notcontains $Node.Template){
                        $NodeTemplateChecked += $Node.Template
                    }

                    Else{
                        $CoresCanMove += $Node.ProcessorCores 
                        $NodesCanMove += $Node
                    }

                    If($TemplateNodeMap.ContainsKey($Node.Template) -eq $True){
                        $NewValue = $TemplateNodeMap.Get_Item($Node.Template)
                        $NewValue += 1
                        $TemplateNodeMap.Set_Item($Node.Template,$NewValue)
                        $NewCores = $TemplateCoreMap.Get_Item($Node.Template)
                        $NewCores += $Node.ProcessorCores
                        $TemplateCoreMap.Set_Item($Node.Template,$NewCores)
                        }

                    Else{
                        $TemplateNodeMap.Set_Item($Node.Template,1)
                        $TemplateCoreMap.Set_Item($Node.Template,$Node.ProcessorCores)
                    }            
                }

                $BalancedPercentage = 100 / $BusyTempCount
                $NodesToMove = @()
                $UpperPercThreshold = $BalancedPercentage + $PercentageTolerance
                $LowerPercThreshold = $BalancedPercentage - $PercentageTolerance

                LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:PREPARATION NodesCanMove:$NodesCanMoveCount CoresCanMove:$CoresCanMove BalancedPercentage:$BalancedPercentage PercentageTolerance:$PercentageTolerance UpperThreshold:$UpperPercThreshold LowerThreshold:$LowerPercThreshold"  

                <#
                If($NodesCanMoveCount -gt $BusyTempCount){

                    ForEach($Key in $TemplateNodeMap.GetEnumerator()){

                        $Perc = $($Key.Value) / $TotalNodes * 100
                        LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC NodeTemplate:$($Key.Name) ExtraNodes:$($key.Value) Percentage:$Perc"
            
                        If($Perc -le $UpperPercThreshold -and $Perc -ge $LowerPercThreshold ){
                            LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC NodeTemplate:$($Key.Name) NodesBalanced:$NodesBalanced"
                        }

                        ElseIf($Perc -gt $UpperPercThreshold){
                            $NodesBalanced = $False
                            LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC NodeTemplate:$($Key.Name) NodesBalanced:$NodesBalanced"
                            $NodesToMove += Get-HpcNode -Name $State.BusyNodes.split(",") -TemplateName $($Key.Name)| Sort ProcessorCores | Select-Object -First $BusyTempCount
                        }
          
                        Else{
                        $NodesBalanced = $False
                        LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC NodeTemplate:$($Key.Name) NodesBalanced:$NodesBalanced"
                        }
                }
            }

                Else{
                LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC Msg:`"Insufficient Nodes to Move`""
            }

            #>
                ForEach($Key in $TemplateCoreMap.GetEnumerator()){
                $Perc = $($Key.Value) / $TotalCores * 100
                LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:CORECALC NodeTemplate:$($Key.Name) ExtraCores:$($key.Value) Percentage:$Perc"
                
                If($Perc -le $UpperPercThreshold -and $Perc -ge $LowerPercThreshold){
                            LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:CORECALC NodeTemplate:$($Key.Name) CoresBalanced:$CoresBalanced"
                }
                
                ElseIf($Perc -gt $UpperPercThreshold){
                    $NodesBalanced = $False
                    LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:CORECALC NodeTemplate:$($Key.Name) CoresBalanced:$NodesBalanced"

                    $NodesToMove += Get-HpcNode -Name $State.BusyNodes.split(",") -TemplateName $($Key.Name)| Sort ProcessorCores | Select-Object -First $BusyTempCount
                }

                Else{
                    $CoresBalanced = $False
                    LogInfo -Message "Action:CORECALC NodeTemplate:$($Key.Name) CoresBalanced:$CoresBalanced"
                }
            }

                If($NodesBalanced -eq $False -or $CoresBalanced -eq $False){
                LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:REBALANCE Msg:`"Grid Balance out of Percentage Tolerance`""

                Set-HpcNodeState -State offline -Force -Node $NodesToMove -ErrorAction SilentlyContinue    
                }
            }
            Else{
                LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -message "Action:Silent Msg:`"Only one active Node Template`"" 
            }
        }
        Else{
            LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:SILENT Msg:`"No Active Jobs to Balance`""
        }

        $NodesToGrow = @() 
        ForEach($Node in $NodesToMove){
            If($NodesToGrow -notcontains $Node){
                $NodesToGrow += $Node
                }
            }
        LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:COMPLETE" 
        Write-Output $NodesToGrow
        }
    Catch{
        LogError -LogFilePrefix $LogFilePrefix -Logging $Logging -message $_.exception.message
        $error.clear()
        }
}
