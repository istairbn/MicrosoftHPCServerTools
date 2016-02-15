#-------------------------------------------------------------------------------------------------------------------#
#Script: MicrosoftHPCServerTools.psm1                                                                               #
#Author: Benjamin Newton - Excelian                                                                                 #
#Version 2.0.0                                                                                                      #
#Keywords: HPC Server,Azure Paas, Auto grow and Shrink, Calls, Monitoring                                           #
#Comments:This module provides tools to enable autoscaling and monitoring of an HPC Server 2012 R2 Environment      #
#-------------------------------------------------------------------------------------------------------------------#

#region Log Functions
#These are included for completeness to make generating logging simpler - feel free to use your own methods
Function Get-LogFileName{
<#
    .Synopsis
    This determines the location of the log file
    
    .Parameter LogFilePrefix
    The Prefix before the dated name
    
    .Example
    Get-LogFileName -TEST
    
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
#Sets a Log File Name

Function Write-LogInfo{
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
    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "5 things happened"
    
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

    [Parameter (Mandatory=$False,Position=1)]
    [string]
    $message
    )

    $LogDate=Get-Date -Format 'yyyy/MM/dd HH:mm:ss'
    $Path = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
    $message = "$LogDate [Info] Component:$Path Status:Online $message"

    if($Logging -eq $true){
        Write-Verbose $message
        $message >> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)
    }
  
    else{
    Write-Host $message
    }
}
#Outputs an Info level Line

Function Write-LogWarning{
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
    Write-LogWarning -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "5 things happened"
    
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

    [Parameter (Mandatory=$False,Position=1)]
    [String]
    $message
    )

    $LogDate=Get-Date -Format 'yyyy/MM/dd HH:mm:ss'
    $Path = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
    $message = "$LogDate [Warning] Component:$Path Status:Online $message"

    if($Logging -eq $true){
        Write-Warning $message
        $message >> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)
    }
    else{
        Write-Host -ForegroundColor Yellow $message
    }
}
#Outputs an Warning level Line

Function Write-LogError{
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
    Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    
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

    [Parameter (Mandatory=$False,Position=1)]
    [string[]]
    $message
    )

    $LogDate=Get-Date -Format 'yyyy/MM/dd HH:mm:ss'
    $Path = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
    $message = "$LogDate [Error] Component:$Path Status:Online $message"

    if($Logging -eq $true){
        Write-Error $message
        $message >> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)
        $error.Clear()
    }
    else{
        Write-Host -ForegroundColor Red $message
        $error.Clear()
    }
}
#Outputs an Error level Line
#endregion

#region Cluster Information
#This region covers the Functions that find information about the current cluster status and setup
Function Get-HPCClusterActiveJobs{

<#
    .Synopsis
    This collects all running and queued HPC Job Objects.
     
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
        
    .Parameter jobTemplates
    Used to limit the search to a specific Job Template Name 
      
    .Parameter JobState
    Used to determine which Jobs should be included. Defaults to running and queued. 
    
    .Example
    Get-HPCClusterActiveJobs -Jobstate queued -jobTemplates Default_Job_Template
    
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
    $JobTemplates,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $JobState = @("Running","Queued")
    )

    Try{
        If ($JobTemplates.Count -ne 0){
            ForEach ($jobTemplate in $JobTemplates){
                $ActiveJobs += @(Get-HpcJob -Scheduler $Scheduler -State $JobState -TemplateName $jobTemplate -ErrorAction SilentlyContinue -verbose)
            }
        }
        Else{
            $ActiveJobs = @(Get-HpcJob -Scheduler $Scheduler -State $JobState -ErrorAction SilentlyContinue -verbose)
        }
    }
    
    Catch [System.Exception]{
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }
    Write-Output $ActiveJobs

}
#Returns an array of Job Objects - defaults to all running but can be filtered. 

Function Get-HPCClusterActiveJobCount{
<#
    .Synopsis
    This counts how many Jobs are active on the grid at the current time. This function is Deprecated - Use Get-HPCClusterActiveJobs Object and Count the Result 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Example
    Get-HPCClusterActiveJobCount
    
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string[]]
    $JobTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $JobState = @("Running","Queued"),

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False
    )

    Try{
        $ActiveJobs = Get-HPCClusterActiveJobs -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -jobTemplates $JobTemplates -JobState $JobState 
        If($ActiveJobs -ne $Null){
            $Count = $ActiveJobs.Count
        }
        Else{
            $Count = 0
        }
    }
    Catch [System.Exception]{
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }
    Write-Output $Count
}
#Returns an Int of amount of jobs

Function Get-HPCClusterWorkload {
<#
    .Synopsis
    This calculates the current load on grid at the current time. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
    
    .Parameter jobTemplates
    Used to check workload for specific job templates only. 

    .Example
    Get-HPCClusterWorkload -jobTemplates Template1 -Logging $False
    
    .Notes
    Used to determine what the current load is - pass it to Get-HPCClusterGrowCheck

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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

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

        $ActiveJobs = Get-HPCClusterActiveJobs -LogFilePrefix $LogFilePrefix -Logging $Logging -jobTemplates $jobTemplates -Scheduler $Scheduler
        Write-Verbose "Get-HPCClusterActiveJobs: $($ActiveJobs | Out-String)"
    }

    Catch {
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message 
    }

    Try {
        foreach ($Job in $ActiveJobs) {
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
        $MSG = "Action:REPORTING Scheduler:$Scheduler Duration:$Duration AvgSecs:$AvgSecs TotalCalls:$TotalCalls OutstandingCalls:$OutstandingCalls CompletedCalls:$CompletedCalls RunningCalls:$RunningCalls AllocatedCores:$AllocatedCores GridRemainingMins:$GridRemainingMins GridRemainingSecs:$GridRemainingSecs"
        Write-Verbose $MSG
    }

    Catch {
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message 
    }

    $JobAggregateObject = New-Object -TypeName PSObject -Property @{Scheduler=$Scheduler;Duration=$Duration;AvgSecs=$AvgSecs;TotalCalls=$TotalCalls;OutstandingCalls=$OutstandingCalls;CompletedCalls=$CompletedCalls;RunningCalls=$RunningCalls;AllocatedCores=$AllocatedCores;GridRemainingMins=$GridRemainingMins;GridRemainingSecs=$GridRemainingSecs}
    Write-Output $JobAggregateObject
}
#Returns a custom object detailing the current information regarding the Grid use.

Function Get-HPCClusterElements{
<#
    .Synopsis
    This Write-Outputs the current elements and setup of the Grid in the form of an object.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter ServiceConfigLocation
    In order to get the services, we need to know the location on the Scheduler of the HpcServiceRegistration folder - which is set to the default. If you've changed it, you'll need to set it

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter FetchServices
    Getting services takes a little longer (needs access to ServiceConfig path) - turn it off if you don't need it

    .Parameter ServiceConfigLocation
    Path to services - only change if you've changed from the defaults. 

    .Example
    Get-HPCClusterElements -Logging $False 
        
    .Notes
    Used to grab information about the cluster. This is unfiltered, designed to be used for reporting and exporting rather than building services. 

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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [bool]
    $FetchServices = $True,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [string]
    $ServiceConfigLocation = "HpcServiceRegistration"


    )

    Try{

        $Nodes = Get-HpcNode -Scheduler $Scheduler 
        $Groups = Get-HpcGroup -Scheduler $Scheduler
        $Pools = Get-HpcPool -Scheduler $Scheduler
        $NodeTemplates = Get-HpcNodeTemplate -Scheduler $Scheduler
        $JobTemplates = Get-HpcJobTemplate -Scheduler $Scheduler

        $GroupList = @()
        forEach($Group in $Groups){
            $GroupList += $Group.Name
            }

        $PoolList = @()
        forEach($Pool in $Pools){
            $PoolList += $Pool.Name
        }

        $NodeList = @()
        forEach($Node in $Nodes){
            $NodeList += $Node.NetBiosName
        }

        $NodeTemplateList = @()
        forEach($NodeTemplate in $NodeTemplates){
            $NodeTemplateList += $NodeTemplate.Name
        }

        $JobTemplateList = @()
        forEach($JobTemplate in $JobTemplates){
            $JobTemplateList += $JobTemplate.Name
        }
        
        $ServiceList = @()

        If($FetchServices){
            #Gets the Services
            $ServiceConfigPath = "\\" + $Scheduler+ "\" + $ServiceConfigLocation
            $ServiceConfigs = Get-ChildItem -Path $ServiceConfigPath -ErrorAction Continue

            If($ServiceConfigs.Count -ne 0){
                ForEach($Service in $ServiceConfigs){
                    $ServiceName = $Service.BaseName 
                    $ServiceList += $ServiceName
                }
            }
        }

        $Obj = New-Object psobject -Property @{Scheduler=$Scheduler;Groups=$GroupList;Pools=$PoolList;Node=$NodeList;JobTemplate=$JobTemplateList;NodeTemplate=$NodeTemplateList;Service=$ServiceList}
        Write-Output $Obj

        }

    Catch [System.Exception]{
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        $Error.Clear()
    
    }
}
#Returns a custom object detailing the current elements that make up the Grid (i.e. What services are available!)

Function Get-HPCClusterNodeDetail{
<#
    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER
)
    $AllNodes = Get-HPCNode -Scheduler $Scheduler

        foreach ($NODE in $AllNodes){ 
            $ThisNodeName = $Node.NetBiosName
            $ARRAY = @()
            
            $Array += [char]34+"NetBiosName"+[char]34+":"+[char]34+$Node.NetBiosName+[char]34+","
            $Array += [char]34+"DomainName"+[char]34+":"+[char]34+$Node.DomainName+[char]34+","
            $Array += [char]34+"FullyQualifiedDnsName"+[char]34+":"+[char]34+$Node.FullyQualifiedDnsName+[char]34+","
            $Array += [char]34+"ManagementIpAddress"+[char]34+":"+[char]34+$Node.ManagementIpAddress+[char]34+","
            $Array += [char]34+"PxeBootMac"+[char]34+":"+[char]34+$Node.PxeBootMac+[char]34+","
            $Array += [char]34+"NodeSID"+[char]34+":"+[char]34+$Node.NodeSID+[char]34+","
            $Array += [char]34+"MachineGuid"+[char]34+":"+[char]34+$Node.MachineGuid+[char]34+","
            $Array += [char]34+"InstanceId"+[char]34+":"+[char]34+$Node.InstanceId+[char]34+","
            $Locale = $Node.Location.Replace("\",".")
            $Array += [char]34+"Location"+[char]34+":"+[char]34+$Locale+[char]34+","
            $Array += [char]34+"Description"+[char]34+":"+[char]34+$Node.Description+[char]34+","
            $Array += [char]34+"NodeState"+[char]34+":"+[char]34+$Node.NodeState+[char]34+","
            $Array += [char]34+"NodeHealth"+[char]34+":"+[char]34+$Node.NodeHealth+[char]34+","
            $Array += [char]34+"HealthState"+[char]34+":"+[char]34+$Node.HealthState+[char]34+","
            $Array += [char]34+"ServiceHealth"+[char]34+":"+[char]34+$Node.ServiceHealth+[char]34+","
            $Array += [char]34+"Provisioned"+[char]34+":"+[char]34+$Node.Provisioned+[char]34+","
            $Array += [char]34+"ProcessorCores"+[char]34+":"+[char]34+$Node.ProcessorCores+[char]34+","
            $Array += [char]34+"Sockets"+[char]34+":"+[char]34+$Node.Sockets+[char]34+","
            $Array += [char]34+"Memory"+[char]34+":"+[char]34+$Node.Memory+[char]34+","
            $Array += [char]34+"CcpVersion"+[char]34+":"+[char]34+$Node.CcpVersion+[char]34+","
            $Array += [char]34+"Version"+[char]34+":"+[char]34+$Node.Version+[char]34+","
            $Array += [char]34+"Template"+[char]34+":"+[char]34+$Node.Template+[char]34+","
            $Array += [char]34+"Groups"+[char]34+":"+[char]34+$Node.Groups+[char]34+","
            $Array += [char]34+"ProductKey"+[char]34+":"+[char]34+$Node.ProductKey+[char]34+","
            $Array += [char]34+"NodeRole"+[char]34+":"+[char]34+$Node.NodeRole+[char]34+","
            $Array += [char]34+"IsHeadNode"+[char]34+":"+[char]34+$Node.IsHeadNode+[char]34+","
            $Array += [char]34+"SubscribedCores"+[char]34+":"+[char]34+$Node.SubscribedCores+[char]34+","
            $Array += [char]34+"SubscribedSockets"+[char]34+":"+[char]34+$Node.SubscribedSockets+[char]34+","
            $Array += [char]34+"Affinity"+[char]34+":"+[char]34+$Node.Affinity+[char]34+","
            $Array += [char]34+"AzureBatchComputeNodes"+[char]34+":"+[char]34+$Node.AzureBatchComputeNodes+[char]34+","
            $Array += [char]34+"AzureInstanceSize"+[char]34+":"+[char]34+$Node.AzureInstanceSize+[char]34+","
            
            $OUT = Get-HpcMetricValue -Node $NODE -Scheduler $Scheduler -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                foreach ($LINE in $OUT){
                    $ARRAY += [char]34+$LINE.Metric+[char]34+":"+[char]34+$LINE.Value+[char]34+"," 
                }
                
            $JSON = "{"+$ARRAY+"}"
            $FinalObject = $JSON.Replace(",}","}")

            $FinalObject | ConvertFrom-Json
        }
    
}
#Returns a custom object for each Node, combining Stateful and Static Info. Use the Where-Object Cmndlet to filter

Function Get-HPCClusterStatus{
<#
    .Synopsis
    This Write-Outputs the current status of the Grid in the form of an object, to determine which Groups, Pools and Templates are currently required.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter JobState
    Used to determine which Jobs should be included. Defaults to running for this information. 

    .Parameter jobTemplates
    Used to limit the search to a specific Job Template Name 
    
    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Example
    Get-HPCClusterStatus -Logging $False -ExcludedGroups SlowNodes
        
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $jobTemplates,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedGroups = @("InternalCloudNodes"),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $JobState = @("Running")
    )

    Try{

    $Jobs = Get-HPCClusterActiveJobs -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -JobState $JobState -jobTemplates $JobTemplates 
    $JobCount = $Jobs.Count
    $OverviewData = Get-HpcClusterOverview
    $Groups = @()
    $JobTemplateList = @()
    $NodeTemplates = @()
    $BusyNodes = @()
    $BusyPools = @()
    $AvailableNodes = @()
    $IdleGroups = @()
    $IdlePools = @()
    $IdleCores = 0
    $BusyCores = 0
    $TotalCores = $OverviewData.TotalCoreCount
    $OfflineCores = $OverviewData.OfflineCoreCount
    $ExcludedCores = 0
    $IdleNodes = @()
    $IdleJobTemplates = @()
    $IdleNodeTemplates = @()
    $NodeMasterList = Get-HpcNode -Scheduler $Scheduler -HealthState OK -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $NodeMasterList += Get-HpcNode -Scheduler $Scheduler -HealthState Unapproved -GroupName AzureNodes -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $GroupMasterList = Get-HpcGroup -Scheduler $Scheduler -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $PoolMasterList = Get-HpcPool -Scheduler $Scheduler -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $NodeTemplateMasterList = Get-HpcNodeTemplate -Scheduler $Scheduler -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $JobTemplateMasterList = Get-HpcJobTemplate -Scheduler $Scheduler -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $MappedNodeTemplates = @{}
    $GetNodeDetail = $True

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

                if($JobTemplateList -notcontains $Job.Template){
                    $JobTemplateList += $Job.Template
                    }

                $BusyCores += $Job.CurrentAllocation
            }
            If($BusyNodes.Count -ne 0){
                $NodeObj = Get-HpcNode -Scheduler $Scheduler -Name $BusyNodes.split(",")

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
            if($JobTemplateList -notcontains $JTemp.Name){
                $IdleJobTemplates += $JTemp.Name
                }
            }

        forEach($Template in $NodeTemplateMasterList){
            if($NodeTemplates -notcontains $Template.Name -and ($Template.Name -match "HeadNode" -or $Template.Name -match "Broker") -and $ExcludedNodeTemplates -notcontains $Template.Name){
                $IdleNodeTemplates += $Template.Name
                }
            if($NodeTemplates -notcontains $Template.Name -and ($Template.Name -match "HeadNode" -or $Template.Name -match "Broker")){
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
            
            $AvailableComputeCores = [math]::Round($IdleCores+$BusyCores)
           
            If($AvailableComputeCores -lt 1){ 
                $AvailableComputeCores = 0
                $PercentComputeCoresUtilised = 0
            }
            Else{
                $PercentComputeCoresUtilised =[math]::Round($BusyCores / $AvailableComputeCores * 100)
            }

            $PercentTotalCoresUnavailable =[math]::Round(($OfflineCores - $ExcludedCores) / ($TotalCores - $ExcludedCores) * 100)
            $PercentTotalCoresAvailable = [math]::Round(100 - $PercentTotalCoresUnavailable)
            $PercentComputeCoresUnutilised = [math]::Round(100 - $PercentComputeCoresUtilised)
            
            
            $Obj = New-Object psobject -Property @{
                Scheduler=$Scheduler;ClusterName=$Scheduler;
                BusyGroups=$Groups;ExcludedGroups=$ExcludedGroups;IdleGroups=$IdleGroups;
                BusyPools=$BusyPools;IdlePools=$IdlePools;
                BusyNodes=$BusyNodes;IdleNodes=$IdleNodes;ExcludedNodes=$ExcludedNodes;
                BusyJobTemplates=$JobTemplateList;IdleJobTemplates=$IdleJobTemplates;
                BusyNodeTemplates=$NodeTemplates;IdleNodeTemplates=$IdleNodeTemplates;ExcludedNodeTemplates=$ExcludedNodeTemplates;
                #Deals with Total Cores
                TotalCores=$TotalCores;BusyCores=$BusyCores;IdleCores=$IdleCores;ExcludedCores=$ExcludedCores;OfflineCores=$OfflineCores;
                PercentTotalCoresAvailable=$PercentTotalCoresAvailable;PercentTotalCoresUnavailable=$PercentTotalCoresUnavailable;
                #Deals with Compute Cores only
                AvailableComputeCores=$AvailableComputeCores;
                PercentComputeCoresUtilised=$PercentComputeCoresUtilised;PercentComputeCoresUnutilised=$PercentComputeCoresUnutilised
            }
            Write-Output $Obj
            
        }

    Catch [System.Exception]{
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        $Error.Clear()
    
    }
}
#Returns a custom object with the string values referring to various types of Objects (eg Names of Busy Nodes)

Function Get-HPCClusterRegistry{
<#
    .Synopsis
    This gets relevant HPC Server 2012 entries
    
    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
    
    .Example
    Get-HPCClusterRegistry
    
    .Notes
    Used to ensure SQL databases are correctly sought

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER
    )
    Try{
    Invoke-Command -ComputerName $Scheduler -ScriptBlock{
        Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\HPC
    }
    }
    Catch [System.Exception]{
        Write-LogError $Error.ToString()
        $Error.Clear()
    }
}
#Returns the Registry Entries

Function Get-HPCClusterJobRequirements{

<#
    .Synopsis
    This Write-Outputs the current status of the Grid in the form of an object, to determine which Groups, Pools and Templates are currently required.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter JobTemplates
    Limit the check to certain job templates

    .Example
    Get-HPCClusterStatus -Logging $False -ExcludedGroups SlowNodes
        
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

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $JobTemplates,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER
    )
    Try{
        Add-PSSnapin Microsoft.hpc
    }
    Catch [System.Exception]{
        Write-LogError $Error
        $Error.clear()
        Exit
    }
    $Jobs = Get-HPCClusterActiveJobs -JobState Queued,Running -jobTemplates $JobTemplates -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging

    $RequiredGroups = @()
    $RequiredJobTemplates = @()
    $RequiredNodes = @()
    $RequiredPools = @()


    ForEach($Job in $Jobs){
        If($Job.NodeGroups.Count -ne 0){
            $JobGroups = $Job.NodeGroups.split(",")
            ForEach($GP in $JobGroups){
                If($RequiredGroups -notcontains $GP){
                    $RequiredGroups += $GP
                }
            }
        }

        If($RequiredJobTemplates -notcontains $Job.Template){
            $RequiredJobTemplates += $Job.Template
        }

        If($RequiredPools -notcontains $Job.Pool){
            $RequiredPools += $Job.Pool
        }

        If($Job.RequestedNodes -ne $Null){  
            $RequiredNodes += $Job.RequestedNodes
        }
    }

    $Obj = New-Object -Type PsObject -Property @{RequiredGroups=$RequiredGroups;RequiredJobTemplates=$RequiredJobTemplates;RequiredNodes=$RequiredNodes;RequiredPools=$RequiredPools}

    Write-Output $Obj
}
#Returns a custom object with the Groups, Job Templates and Pools needed to for current Jobs.

Function Sync-HPCClusterJobAndNodeTemplates{
<#
    .Synopsis
    This collects the default Node Template for each Job Template - later used for re-assigning ComputeNodes.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered 

    .Parameter ExcludedNodes
    Determines which Node will not be considered 

    .Example
    Sync-HPCClusterJobAndNodeTemplates -Logging $False -ExcludedNodeTemplates -TestNodeTemplate
        
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $Logging=$False,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodes = @(),

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $ExcludedNodeTemplates = @()
    )

    Try{
        $JobNodeTemplateMap = @{}
        $Status= Get-HPCClusterStatus -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -JobState "Queued" -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes 
        $TempGroupMap = Export-HPCClusterDefaultGroupFromTemplate -Scheduler $Scheduler

        Foreach($JTemp in $Status.BusyJobTemplates){
            $MappedYet = @()

            Foreach($Node in $Status.BusyNodes){
                $it = Get-HpcNode -Scheduler $Scheduler -Name $Node -GroupName $TempGroupMap.Item($JTemp) -ErrorAction SilentlyContinue

                If($MappedYet -notcontains $it.Template){
                    If($it.Template -ne $null -and $ExcludedNodeTemplates -notcontains $it.Template){
                        $MappedYet += $it.Template
                    }
                }
            }

            $JobNodeTemplateMap += @{$Jtemp=$MappedYet}
        }

        Write-Output $JobNodeTemplateMap
    }
    Catch [System.Exception]{
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        $Error.clear()
    }
}
#Returns a HashMap of Job and Node Templates - linking their defaults. Used for moving Nodes around.

Function Export-HPCClusterDefaultGroupFromTemplate{
<#
    .Synopsis
    This extracts the default Group for a Job Template. Can Take either one template or generate a hash table for all 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
    
    .Parameter Templates
    You can specify which Job Template to analyse, otherwise it will just get them all. 

    .Example
    Export-HPCClusterDefaultGroupFromTemplate -Logging $False -Templates JobTemplate1,JobTemplate2
    
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [Microsoft.ComputeCluster.CCPPSH.HpcJobTemplate[]] 
    $Templates = @()
    )

    Try{
        $TemplateMap = @{}

        If($Templates.Count -eq 0){
            $Templates = Get-HpcJobTemplate -Scheduler $Scheduler 
            }

        foreach($Template in $Templates){
            Export-HpcJobTemplate -Scheduler $Scheduler -Template $Template -Path .\temp.xml -Force -ErrorAction SilentlyContinue 
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
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }

}
#Returns a HashMap of Job Templates and their default groups. Underlying workhorse for Syncing Job and Node Templates
#endregion

#region Cluster Growth
Function Get-HPCClusterGrowCheck{
<#
    .Synopsis
    This calculates whether the load on the Grid requires more resources. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean wether or not to create a log or just display host output

   .Parameter OutstandingCalls
   Amount of Calls awaiting completion - collected from Get-HPCClusterWorkload

   .Parameter Get-HPCClusterActiveJobs
    The current Jobs. Use Get-HPCClusterActiveJobs to create the object required

   .Parameter CallQueueThreshold
    The number of queued calls required to set off a growth of Nodes.Default is 2000

   .Parameter GridRemainingMins
    Minutes of Grid time remaining. Sourced from Grid Workload

   .Parameter NumOfQueuedJobsToGrowThreshold
    The number of queued jobs required to set off a growth of Nodes. The default is 1. For SOA sessions, this should be set to 1 

   .Parameter GridMinsRemainingThreshold
    The time in minutes, of remaining Grid work. If this threshold is exceeded, more Nodes will be allocated. Default is 30

    .Example
    $Jobs = Get-HPCCLusterActiveJobs
    Get-HPCClusterWorkload | Get-HPCClusterGrowCheck -Logging $False -CallQueueThreshold 1500 -ActiveJobs $Jobs
    
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

    [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True)]
    [Microsoft.ComputeCluster.CCPPSH.HpcJob[]]
    $ActiveJobs,

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
    $GridMinsRemainingThreshold= 20
    )

    Try{
        $GROW = $False

        if($CallQueueThreshold -ne 0){
    
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "CallQueueThreshold:$CallQueueThreshold CallQueue:$OutstandingCalls"
            
            if($OutstandingCalls -ge $CallQueueThreshold){
                $GROW = $true
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "CallQueueThreshold Exceeded"
            }
        }

        if($GridMinsRemainingThreshold -ne 0 ){

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "GridMinsRemainingThreshold:$GridMinsRemainingThreshold GridMinsRemaining:$GridRemainingMins"
            
            if($GridRemainingMins -ge $GridMinsRemainingThreshold){
                $GROW = $true
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "GridMinsRemainingThreshold Exceeded"
            }
        }
    
        if($NumOfQueuedJobsToGrowThreshold -ne 0){
    
            $queuedJobs = @($ActiveJobs | ? { $_.State -eq 'Queued' } )
            $QJobCount = $queuedJobs.Count

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "QueuedJobsThreshold:$NumOfQueuedJobsToGrowThreshold QueuedJobs:$QJobCount"

            if($queuedJobs.Count -ge $NumOfQueuedJobsToGrowThreshold){
                $GROW = $true
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "QueuedJobsThreshold Exceeded"
            }
        }
    
    }

    Catch [System.Exception]{
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }

    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE GrowState:$GROW"

    Write-Output $Grow
}
#Returns a Boolean to confirm whether or not the Grid needs to Grow. Must be given Get-HPCClusterActiveJobs and Get-HPCClusterWorkload

Function Get-HPCClusterNodesRequired{
    [CmdletBinding()]
    <# 
   .Synopsis 
   This checks the Groups and Requested Nodes, then generates the Nodes that match for growth

   .Parameter JobTemplates
    Specifies the names of the job templates to define the workload for which the nodes to grow. If not specified (the default value is @()), all active jobs are in scope for check.

    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter NodeGroups
    Which Groups will be considered

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

   .Parameter Scheduler
    The scheduler used. Defaults to the one in use by the Environment

   .Parameter Logging
    Whether the script creates a Log file or not - location determined by the LogFilePrefix. Default is True

   .Parameter LogFilePrefix
    Specifies the prefix name of the log file, you can include the path, by default the log will be in current working directory

   .Example 
    Get-HPCClusterNodesRequired | Where-Object {$_.NodeState -contains "Online" }

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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string[]]
    $JobTemplates,

    [Parameter (Mandatory=$False)]
    [string[]]
    $ExcludedGroups = @("AzureNodes","ComputeNodes"),

    [Parameter (Mandatory=$False)]
    [string[]]
    $ExcludedNodeTemplates=@(),

    [Parameter (Mandatory=$False)]
    [string[]]
    $ExcludedNodes=@()
    )

    Try{
        Add-PSSnapin Microsoft.hpc
     }
     Catch [System.Exception]{
        Write-LogError $Error
        $Error.Clear()
        Exit
     }  

        $Status = Get-HPCClusterStatus -JobTemplates $JobTemplates -LogFilePrefix $LogFilePrefix -Logging $Logging  -Scheduler $Scheduler -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedGroups $ExcludedGroups -ExcludedNodes $ExcludedNodes

        $Requirements = Get-HPCClusterJobRequirements -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler -JobTemplates $JobTemplates

        $NewStart = $False
        $Nodes = @()
        $ReqNodes = $Requirements.RequiredNodes | Measure-Object 
        If($ReqNodes.Count -ne 0){
            ForEach($ReqNode in $Requirements.RequiredNodes){
                $Nodes += Get-HPCNode -Scheduler $Scheduler -Name $ReqNode
            }
        }
        If($Requirements.RequiredGroups.Count -ne 0){
            ForEach($Group in $Requirements.RequiredGroups){
                If($Status.ExcludedGroups -notcontains $Group){
                    $Nodes += Get-HPCNode -Scheduler $Scheduler -GroupName $Requirements.RequiredGroups
                }
            }
        }
        Else{
            $Nodes += Get-HPCNode -Scheduler $Scheduler
        }
        

        $Nodes = @($Nodes | ? { $Status.ExcludedNodes -notcontains $_.NetBiosName})
        $Nodes = @($Nodes | ? { $Status.ExcludedNodeTemplates -notcontains $_.Template})

        Write-Output $Nodes
}
#Returns a collection of Node objects that can be passed to Start-HPCClusterNodes

Function Start-HPCClusterNodes{
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

    .Parameter InitialGrow-HPCClusterNodes
    If less than 1 Node alive, how many should be grown. Default is 10.

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter Start-HPCClusterNodes
    Assuming more than 1 node currently exists (i.e. the Grid is currently running) how much more should be assigned.

    .Example
    To autoscale your Azure Nodes up: Start-HPCClusterNodes -NodeGroup AzureNodes
    
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

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $Scheduler = $env:CCP_SCHEDULER,

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $NodeGroup="AzureNodes,ComputeNodes",

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $ExcludedNodes=@(),

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $NodeTemplates,

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $ExcludedNodeTemplates = @(),

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [int] 
        $InitialNodeGrowth=10,

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [int] 
        $NodeGrowth = 5,

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [Microsoft.ComputeCluster.CCPPSH.HpcNode[]]
        $NodesToGrow= @()
    )


    Try{
        $GrowthSuccess = $False

        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING"
        
        if($NodesToGrow.Count -eq 0){
        
            $NodesThatAreReadyToMove = @();

            #Collect group of available Nodes
            if ($NodeTemplates.Count -ne 0){
                    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:CALCULATING Groups:$NodeGroup Templates:$NodeTemplates"
                    $NodesThatAreReadyToMove = @(Get-HpcNode -Scheduler $Scheduler -GroupName $NodeGroup.split(",") -TemplateName $NodeTemplates -State Offline,NotDeployed -ErrorAction SilentlyContinue -Verbose) 
                }
        
            else{
                    $NodesThatAreReadyToMove = @(Get-HpcNode -Scheduler $Scheduler -GroupName $NodeGroup.split(",") -ErrorAction SilentlyContinue -State Offline,NotDeployed -Verbose)
                    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:CALCULATING Groups:$NodeGroup"
                }
            }
        
        else{
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:NODESGIVEN"
            $NodesThatAreReadyToMove = $NodesToGrow
        }

        $NodesThatAreReadyToMove = @($NodesThatAreReadyToMove | ? { $ExcludedNodes -notcontains $_.NetBiosName})
        $NodesThatAreReadyToMove = @($NodesThatAreReadyToMove | ? { $ExcludedNodeTemplates -notcontains $_.Template})

        $targetNodes = @();
        $onlineNodes = @();

        #Find nodes not yet online or deployed
        forEach($node in $NodesThatAreReadyToMove){
            if($node.NodeState -eq "NotDeployed" -or $node.NodeState -eq "Offline"){
                $targetNodes += $node
                }
            if($node.NodeState -eq "Online" -or $node.NodeState -eq "Provisioning"){
                $onlineNodes += $node
                }
            }

        $NodesActive = $False
        $GrowNumber = $InitialNodeGrowth
        
        #Check to see if there are any nodes currently online
        if($onlineNodes.Count -gt 0){
            $NodesActive = $True
            $GrowNumber = $GrowNodeGrowth
        }

        $SortedTarget = $targetNodes | Sort-Object NodeState,ProcessorCores,Memory
        $UndeployedTargetNodes = @()
        $OfflineTargetNodes = @()

        if($targetNodes.Count -gt 0){
                forEach($target in $SortedTarget[0..($GrowNumber - 1)]){
                    $TName = $target.NetBiosName
                    if($target.NodeState -eq "NotDeployed"){
                        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Node:$TName State:NotDeployed Action:DEPLOYING"
                        $UndeployedTargetNodes += $target
                    }
                    elseif($target.NodeState -eq "Offline"){
                        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Node:$TName State:Offline Action:SETONLINE"
                        $OfflineTargetNodes += $target
                        }
                    }

                #First, switch offline nodes online, then deploy new nodes
                if($OfflineTargetNodes.Count -ne 0){
                    If($Logging -eq $true){
                        Set-HpcNodeState -Scheduler $Scheduler -State online -Node $OfflineTargetNodes -ErrorAction SilentlyContinue -Verbose  *>> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)  
                        }
                    Else{
                        Set-HpcNodeState -Scheduler $Scheduler -State online -Node $OfflineTargetNodes -ErrorAction SilentlyContinue -Verbose 
                    }
                    }

                if($UndeployedTargetNodes.Count -ne 0){
                        If($Logging -eq $true){
                            Start-HpcAzureNode -Scheduler $Scheduler -Node $UndeployedTargetNodes -Async $false -ErrorAction SilentlyContinue -Verbose *>> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)   
                            Set-HpcNodeState -Scheduler $Scheduler -State online -Node $UndeployedTargetNodes -ErrorAction SilentlyContinue -Verbose  *>> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)  
                        }
                        Else{
                            Start-HpcAzureNode -Scheduler $Scheduler -Node $UndeployedTargetNodes -Async $false -ErrorAction SilentlyContinue -Verbose
                            Set-HpcNodeState -Scheduler $Scheduler -State online -Node $UndeployedTargetNodes -ErrorAction SilentlyContinue -Verbose                          
                    }
                }
                $GrowthSuccess = $True
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE GrowthSuccess:$GrowthSuccess Msg:`"Node Growth Complete`""
            }

        else{
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:NOTHING GrowthSuccess:$GrowthSuccess Groups:$NodeGroup Msg:`"No Suitable Nodes Available`""
            }
        
        Write-Output $GrowthSuccess
    }
    
    Catch [System.Exception]{
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }

}
#Returns a Boolean to determine success. Turns on Nodes according to Parameters. If you only want to scale one template, you must send the Nodes yourself!
#endregion

#region Cluster Groups
#This region deals with all functions related to moving Nodes around
Function Set-HPCClusterOneNodePerGroup{
<#
    .Synopsis
    This ensures at least one Node is running for each Group. Defaults to ComputeNodes only.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter NodeGroup
    Determines which Nodes will be kept alive, if blank any. Defaults to ComputeNodes

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter ExcludedGroups
    Determines which groups are NOT discriminated on. Defaults to AzureNodes,ComputeNodes

    .Parameter ExcludedNodes
    Determines which Nodes are not touched

    .Example
    Set-HPCClusterOneNodePerGroup -Logging $False -NodeGroup AzureNodes,ComputeNodes -ExcludedGroups Group1
    
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

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
    $NodeMoved = $False
    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING"
    $ExcludedArray = $ExcludedGroups.Split(",")
    $MoreThanOneNode = $False
    $Workers = Get-HpcNode -Scheduler $Scheduler -GroupName $NodeGroup -State Online,Provisioning -HealthState OK -ErrorAction SilentlyContinue -Verbose
    $Slackers = Get-HpcNode -Scheduler $Scheduler -GroupName $NodeGroup -State Offline -HealthState OK -ErrorAction SilentlyContinue -Verbose

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
    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:EXCEEDED Groups:`"$Array`""

    ForEach($Node in $Slackers){
        $Array = $Node.Groups.Split(",")
        forEach($GP in $Array){
            if($Groups -notcontains $GP -and $ExcludedArray -notcontains $GP){
                $Groups += $GP
                $Name = $Node.NetBiosName
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  " Action:SETONLINE Node:$Name Group:$GP"
                Set-HpcNodeState -Scheduler $Scheduler -State online -Node $Node -Verbose
            }
        }
    }
    
        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETED MoreThanOneNode:$MoreThanOneNode NodeMoved:$NodeMoved"
    }
    
    Catch [System.Exception]{
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
    }
}
#Returns nothing, ensures every group has at least one Node active

Function Remove-HPCClusterGroups{
<#
    .Synopsis
    This strips the groups (excluding system groups 1-9) from a Template, so the template can be switched and a new discriminator applied. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter NodesToGrow
    A collection of Nodes you want to strip.

    .Parameter OutputNodes
    If you need the Node Objects you've moved, set this to true 

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter ExcludedGroups
    If you have a group that you want to leave assigned, excluded groups will stop it from being stripped.

    .Example
    Get-HPCClusterIdleDifferentNodes -NodeGroup ComputeNodes,AzureNodes | Remove-HPCClusterGroups -ExcludedGroups Group1,Group2 | Convert-HPCClusterTemplate
    
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

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $Scheduler = $env:CCP_SCHEDULER,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [bool]
        $OutputNodes = $False,

        [Parameter (Mandatory=$True,ValueFromPipeline=$True)]
        [Microsoft.ComputeCluster.CCPPSH.HpcNode[]]
        $NodesToGrow = @(),

        [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [String[]] 
        $ExcludedGroups = @()

        )

        Try{

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING"

            $ALL = Get-HpcGroup -Scheduler $Scheduler |? {$_.ID -gt 9}
       
            $ToStrip = @()


            $Status = Get-HPCClusterStatus -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedGroups $ExcludedGroups
            ForEach($Group in $All){
                If($Status.ExcludedGroups -notcontains $Group.Name){
                   $ToStrip += $Group.Name
                }
            }

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:REMOVING GROUPS:$ToStrip"

            Set-HpcNodeState -Scheduler $Scheduler -Node $NodesToGrow -State offline -Force -errorAction SilentlyContinue
            Remove-HpcGroup -Scheduler $Scheduler -Name $ToStrip -Node $NodesToGrow -Confirm:$false

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETED"
            
            If($OutputNodes){
                Write-Output $NodesToGrow
            }
        }
        Catch{
            Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        }
}
#Returns either nothing or the nodes that have been denuded of their groups!
#endregion

#region Cluster Shrink
Function Get-HPCClusterShrinkCheck{
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

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Example
    Get-HPCClusterShrinkCheck -NodeGroup AzureNodes
    
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

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
        $SHRINK = $False
        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING"
        $NodesAvailable = @();
        $State = Get-HPCClusterStatus -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups
        $Counter = $State.IdleNodes

        If($Counter.Count -ne 0){
            if ($NodeTemplates.Count -ne 0){
                $idleNodes = @(Get-HpcNode -Scheduler $Scheduler -GroupName $NodeGroup.split(",") -Name $State.IdleNodes -State Online -TemplateName $NodeTemplates -ErrorAction SilentlyContinue -Verbose)
                
                if($NodeGroup -contains "AzureNodes"){
                    $idleNodes += @(Get-HpcNode -Scheduler $Scheduler -GroupName AzureNodes -Name $State.IdleNodes -State Offline -TemplateName $NodeTemplates -ErrorAction SilentlyContinue -Verbose)
                }
            }
            else{
                $idleNodes = @(Get-HpcNode -Scheduler $Scheduler -GroupName $NodeGroup.split(",") -Name $State.IdleNodes -ErrorAction SilentlyContinue -State Online -Verbose)
                if($NodeGroup -match "AzureNodes"){  
                    $idleNodes += @(Get-HpcNode -GroupName AzureNodes -Scheduler $Scheduler -Name $State.IdleNodes -State Offline -ErrorAction SilentlyContinue -Verbose)
                }
            }
        }

        Else{
           Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE ShrinkState:$SHRINK"
        }
        
        If($IdleNodes.Count -ne 0){
            # remove head node if in the list
            if ($NodeGroup -eq $NodeGroup.ComputeNodes){
                $idleNodes = @($NodesAvailable | ? { -not $_.IsHeadNode })
        }

            if ($idleNodes.Count -ne 0){
                    $SHRINK = $true
            }

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE ShrinkState:$SHRINK"
       }

       Else{
           Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE ShrinkState:$SHRINK"
       }
    $Checked = New-Object -TypeName PSObject -Property @{Scheduler=$Scheduler;SHRINK=$SHRINK;IdleNodes=$idleNodes;NodesList=$State.IdleNodes;}
    Write-Output $Checked
    } 

    Catch [System.Exception]{
    
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        }
}
#Exports a custom object, containing the Nodes, Node Names, a boolean to determine whether or not to shrink

Function Set-HPCClusterNodesOffline{
<#
    .Synopsis
    This sets the Nodes provided by Shrink Check offline. It does NOT set AzureNodes to Undeployed. Use for balancing as well. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
    
    .Parameter $idlenodes
    Nodes objects to set offline. Pipeline from Get-HPCClusterShrinkCheck 
    
    .Parameter Nodeslist
    List of the Node names for logging. Get-HPCClusterShrinkCheck provides this, if you send your own group then leave blank and it will be filled in. 

    .Parameter SHRINK
    Boolean, if True it will shrink the Nodes. If output piped from Get-HPCClusterShrinkCheck, will determine whether or not Nodes should be set offline

    .Example
    Get-HPCClusterShrinkCheck | Set-HPCClusterNodesOffline -Logging $False
    
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

    [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True)]
    [Microsoft.ComputeCluster.CCPPSH.HpcNode[]] 
    $idlenodes,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

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
        #Since the List is an option, if you just give it nodes it'll determine the names
            If($Nodeslist.count -eq 0){
                ForEach($Node in $idlenodes){
                    $Nodeslist += $Node.NetBiosName
                }
            }

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING NodeCount:$($idleNodes.Count) Nodes:`"$NodesList`""
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:OFFLINE Msg:`"Bringing nodes offline`""
            If($Logging -eq $True){
                Set-HpcNodeState -Scheduler $Scheduler -Node $idleNodes -State offline -WarningAction Ignore -ErrorAction SilentlyContinue -Verbose *>> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)   
            }
            Else{
                Set-HpcNodeState -Scheduler $Scheduler -Node $idleNodes -State offline -WarningAction Ignore -ErrorAction SilentlyContinue -Verbose
            }
            
            $error.Clear();

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE Msg:`"Nodes offline`""

            $OfflineSuccess = $True
        }
        Else{
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message "Action:COMPLETE Msg:`"No Nodes to Shrink`""
        }
    }

    Catch [System.Exception] {
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        }
   Write-Output $OfflineSuccess

}
#Returns a boolean to determine the success of turning the nodes offline.

Function Set-HPCClusterNodesUndeployedOrOffline{
<#
    .Synopsis
    This shrinks the Nodes provided by Shrink Check - setting ComputeNodes offline and Undeploying AzureNodes. It means redeploying the Azure Nodes will take longer. 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
 
    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
   
    .Parameter $idlenodes
    Nodes objects to shrink. Pipeline from Get-HPCClusterShrinkCheck 
    
    .Parameter Nodeslist
    List of the Node names for logging. Get-HPCClusterShrinkCheck provides this, if you send your own group then leave blank and it will be filled in. 

    .Parameter SHRINK
    Boolean, if True it will shrink the Nodes. If output piped from Get-HPCClusterShrinkCheck, will determine whether or not Nodes should be shrunk

    .Example
    Get-HPCClusterShrinkCheck | Set-HPCClusterNodesUndeployedOrOffline -Logging $False
    
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [bool] 
    $SHRINK=$True
    )

    Try{
        $ShrinkSuccess = $false
        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:STARTING NodeCount:$($idleNodes.Count)"

        If($SHRINK -eq $True){
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:OFFLINE Msg:`"Bringing nodes offline`""
        
            If($Logging -eq $True){
                Set-HpcNodeState -Scheduler $Scheduler -Node $idleNodes -State offline -WarningAction Ignore -ErrorAction SilentlyContinue -Verbose *>> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)   
            
                $error.Clear();

                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:NOTDEPLOYED Msg:`"Setting Nodes to Not Deployed`""

                Stop-HpcAzureNode -Scheduler $Scheduler -Node $idleNodes -Force $false -Async $false -ErrorAction SilentlyContinue *>> $(Get-LogFileName -LogFilePrefix $LogFilePrefix)   
            }

            Else{
                Set-HpcNodeState -Scheduler $Scheduler -Node $idleNodes -State offline -WarningAction Ignore -ErrorAction SilentlyContinue 
            
                $error.Clear();

                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:NOTDEPLOYED Msg:`"Setting Nodes to Not Deployed`""

                Stop-HpcAzureNode -Scheduler $Scheduler -Node $idleNodes -Force $false -Async $false -ErrorAction SilentlyContinue
            }

                if (-not $?){
                    Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Stop Azure nodes failed."
                    Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
                    $ShrinkSuccess = $false
                    }
                
                else{
                    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:COMPLETE Msg:`"Nodes offline`""
                    $ShrinkSuccess = $true
                    }
        }
        Else{
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message   "Action:COMPLETE Msg:`"No Nodes switched offline`""
        }
        Write-Output $ShrinkSuccess
    }

    Catch [System.Exception] {
        Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
        }

}
#Returns a boolean to determine the success of undeployment
#endregion

#region Cluster Balancing

Function Convert-HPCClusterTemplate{
<#
    .Synopsis
    This swaps offline Nodes to templates currently in demand. It assumes that the groups are being used as discriminators and that the Nodes have already had their groups stripped. Designed for ComputeNodes rather than AzureNodes (will not take UnDeployed Nodes). 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter NodesToGrow
    A collection of Nodes you want to grow. Should be recieved from Remove-HPCClusterGroups if using groups as discriminators. 

    .Example
    Get-HPCClusterIdleDifferentNodes | Remove-HPCClusterGroups | Convert-HPCClusterTemplate
    
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

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $Scheduler = $env:CCP_SCHEDULER,

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [String[]]
        $ExcludedNodes = @(),

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [String[]]
        $ExcludedGroups = @(),

        [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [String[]]
        $ExcludedNodeTemplates = @(),

        [Parameter (Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True)]
        [Microsoft.ComputeCluster.CCPPSH.HpcNode[]]
        $NodesToGrow = @()
        )
        
        Try{

            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:STARTING "   
            $SUCCESS = $False
            $Status = Get-HPCClusterStatus -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups
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
                $NodeTempObjs = Get-HpcNodeTemplate -Scheduler $Scheduler -Name $Status.BusyNodeTemplates
                $JobTempObjs = Get-HpcJobTemplate -Scheduler $Scheduler -Name $Status.BusyJobTemplates
                $TemplateMap = Export-HPCClusterDefaultGroupFromTemplate -Scheduler $Scheduler -Templates $JobTempObjs -LogFilePrefix $LogFilePrefix -Logging $Logging
                $NodeJobMap = Sync-HPCClusterJobAndNodeTemplates -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates 
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:CALCULATING Ratio:$Ratio"

                Set-HpcNodeState -Scheduler $Scheduler -Node $NodesToGrow -State offline -Force -errorAction SilentlyContinue 

                $SortedNodes = $NodesToGrow | Sort-Object NodeState,ProcessorCores,Memory
                $NodesPerTemplate = [math]::Floor([decimal]($NodesToGrow.Count * $Ratio))

                If($Ratio -eq 1){

                    $NodeTempName = $NodeTempObjs.Name
                    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:SINGLETEMPLATECHANGE JobTemplate:$TempName  NodeTemplate:$NodeTempName Nodes:$NodeNames"
                    Assign-HpcNodeTemplate -Template $NodeTempObjs -Node $NodesToGrow -Confirm:$false 
                
                    $TemplateMap.GetEnumerator() | % {
                        $GroupToAssign = $($_.Value)   
                    }

                    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:GROUPASSIGN AssignGroups:$GroupToAssign AssignedTo:$NodeNames"
                    Add-HpcGroup -Scheduler $Scheduler -Name $GroupToAssign -Node $NodesToGrow
                    Set-HpcNodeState -Scheduler $Scheduler -Node $NodesToGrow -State online
                }

            Else{
                    $NodeAssigned = @()
                    $CoresPerTemplate = ($CoresToGrow * $Ratio)

                    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:MULTITEMPLATECHANGE Templates:$TempName  Nodes:$NodeNames CoresPerTemplate:$CoresPerTemplate"
                
                    Foreach($JTemplate in $JobTempObjs){
                    
                        $NodeToAssign = @()
                        $AssginedNames = @()
                        $CoresAssigned = 0
                        $NodeTempToSet = $NodeJobMap.Item($JTemplate.Name)
                        $JobTemplateName = $JTemplate.Name
                        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:TEMPLATEASSIGN JobTemplate:$JobTemplateName  NodeTemplate:$NodeTempToSet MaxCoresPerTemplate:$CoresPerTemplate"
                    
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
                            $NodeObjToSet = Get-HpcNodeTemplate -Scheduler $Scheduler -Name $NodeTempToSet
                            $NodesWithWrongTemplates = @()

                            ForEach($Node in $NodeToAssign){
                                $ITName = $Node.NetBiosName
                                If($Node.Template -eq $NodeObjToSet.Name){
                                    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:TEMPLATEASSIGN JobTemplate:$JobTemplateName Node:$ITName NodeTemplate:$NodeTempToSet Msg:`"Template already correct`""
                                }
                                Else{
                                    Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:TEMPLATEASSIGN JobTemplate:$JobTemplateName Node:$ITName NodeTemplate:$NodeTempToSet  Msg:`"Template needs changing`""
                                    $NodesWithWrongTemplates += $Node
                                }
                            }

                            If($NodesWithWrongTemplates.Count -ne 0){
                                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:TEMPLATEASSIGN JobTemplate:$JobTemplateName Node:$ITName NodeTemplate:$NodeTempToSet Nodes:$AssignedNames MaxCoresPerTemplate:$CoresPerTemplate"
                                Assign-HpcNodeTemplate -Scheduler $Scheduler -Template $NodeObjToSet -Node $NodesWithWrongTemplates -Confirm:$false
                            }

                            $GroupToAssign = $TemplateMap.Item($JobTemplateName)

                            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:GROUPASSIGN AssignGroups:$GroupToAssign AssignedTo:$AssignedNames"
                            Add-HpcGroup -Scheduler $Scheduler -Name $GroupToAssign -Node $NodeToAssign
                            Set-HpcNodeState -Scheduler $Scheduler -Node $NodeToAssign -State online
                        }
                    }
                }

            
            Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:COMPLETE"
            $Success = $True
            Write-Output $SUCCESS 
            }

            Else{
                Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Action:NOTHING Msg:`"No Nodes available for Template Swap`""
                Write-Output $SUCCESS
            }
            
        }
        Catch{
            Write-LogError -Logging $Logging -LogFilePrefix $LogFilePrefix -message $_.exception.message
            $Error.Clear()
            Write-Output $SUCCESS
        }
}
#Returns a boolean to confirm the success of the conversion

Function Get-HPCClusterIdleReadyNodes{
<#
    .Synopsis
    This Write-Outputs Node Objects, for nodes that can be simply switched online. Pipe this to Start-HPCClusterNodes
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
    
    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Example
    Get-HPCClusterIdleReadyNodes -ExcludedNodes BATTLESTAR
    
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String[]]
    $JobTemplates = @(),

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

    $NodesToGrow = Get-HPCClusterNodesRequired -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -JobTemplates $JobTemplates | Where-Object  {($_.NodeState -contains "NotDeployed" -or $_.NodeState -contains "Offline") }

    Write-Output $NodesToGrow
}
#Returns the Node Objects of the Idle Nodes matching Busy Templates

Function Get-HPCClusterIdleDifferentNodes{
<#
    .Synopsis
    This Write-Outputs Node Objects,for nodes that can have their template switched. Pipe this to Strip Groups if using discriminators, Start-HPCClusterNodes if not.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as active/passive

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Parameter Start-HPCClusterNodes
    The amount of Nodes to grow by - defaults to 5

    .Parameter NodeGroup
    Determines which Groups should be looked at. Defaults to ComputeNodes (ie All on premises nodes) as you wouldn't often want to swap an AzureNodes Template

    .Example
    Get-HPCClusterIdleDifferentNodes -NodeGroup ComputeNodes,AzureNodes | Remove-HPCClusterGroups | Convert-HPCClusterTemplate
    
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

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

    $State = Get-HPCClusterStatus -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups

    If($State.IdleNodes.Count -ne 0){
        $NodesAvailable = Get-HpcNode -Scheduler $Scheduler -Name $State.IdleNodes -GroupName $NodeGroup -HealthState OK,Unapproved -ErrorAction SilentlyContinue | Sort-Object -Property ProcessorCores,Memory -Descending
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
        Write-LogInfo -Logging $Logging -LogFilePrefix $LogFilePrefix -message  "Msg`"No Nodes Available`""
    }
}
#Returns the Node Objects that can move - irrespective of Template and Group

Function Invoke-HPCClusterSimpleAutoScaler{
<# 
   .Synopsis 
    This function is a simple HPC AutoScale check - if there is a need for more nodes, it expands if it can. If the grid is quiet, it will shut down nodes. Nothing clever or simple, part example and covers very simple use cases.

   .Parameter Scheduler
    The scheduler used. Defaults to the one in use by the Environment

   .Parameter CallQueueThreshold
    The number of queued calls required to set off a growth of Nodes.Default is 2000

   .Parameter GridMinsRemainingThreshold
    The time in minutes, of remaining Grid work. If this threshold is exceeded, more Nodes will be allocated. Default is 30

   .Parameter NumOfQueuedJobsToGrowThreshold
    The number of queued jobs required to set off a growth of Nodes.Default is 1

   .Parameter InitialNodeGrowth
    The initial minimum number of nodes to grow if all the nodes in scope are NotDeployed or Stopped(Deallocated). Default is 10

   .Parameter NodeGrowth
    The amount of Nodes to grow if there are already some Nodes in scope allocated. Compare with $NumInitialNodesToGrow. Default is 5
    
   .Parameter Logging
    Whether the script creates a Log file or not - location determined by the LogFilePrefix. Default is True

   .Parameter LogFilePrefix
    Specifies the prefix name of the log file, you can include the path, by default the log will be in current working directory

   .Example 
    
    while(1) { Invoke-HPCClusterSimpleAutoScaler -CallQueueThreshold 50; Sleep 60 }

   .Notes 
    The prerequisites for running this script:
    1. Add the Azure nodes or the Azure VMs before running the script.
    2. This is not compatibile with the deprecated IAAS VMs. Use the Worker Roles.
    3. The HPC cluster should be running at least HPC Pack 2012 R2 Update 1
    4. You have no control which nodes or groups will grow - use a different Scaler (or write your own!)

   .Link 
   www.excelian.com
#>

Param(
    [CmdletBinding()]

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$False)]
    [String[]] 
    $JobTemplates=@(),

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
    $NumOfQueuedJobsToGrowThreshold=1,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $CallQueueThreshold=2000,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $GridMinsRemainingThreshold= 20,

    [Parameter (Mandatory=$False)]
    [bool]
    $Logging=$False,

    [Parameter (Mandatory=$False)]
    [String]
    $LogFilePrefix="HPCClusterSimpleAutoScaler"

)

    Try{
        Add-PSSnapin Microsoft.hpc
    }
    Catch [System.Exception]{
        Write-LogError $Error
        $Error.Clear()
        Exit 
    }

    $ActiveJobs = Get-HPCClusterActiveJobs -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -jobTemplates $JobTemplates
    $Count = Get-HPCClusterActiveJobCount -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -JobTemplates $JobTemplates

    Write-LogInfo "Jobs:$Count Scheduler:$Scheduler" -Logging $Logging -LogFilePrefix $LogFilePrefix 

    If($Count -ne 0){
    
        $Grow = Get-HpcClusterWorkload -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix | Get-HPCClusterGrowCheck -Logging $Logging -LogFilePrefix $LogFilePrefix -CallQueueThreshold $CallQueueThreshold -GridMinsRemainingThreshold $GridMinsRemainingThreshold -NumOfQueuedJobsToGrowThreshold $NumOfQueuedJobsToGrowThreshold -ActiveJobs $ActiveJobs 
        
        If($Grow){
            $InternalGrow = Start-HPCClusterNodes -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -NodeGroup ComputeNodes -InitialNodeGrowth $InitialNodeGrowth -NodeGrowth $NodeGrowth -
            
            If($InternalGrow -eq $False){
                $AzureGrow = Start-HPCClusterNodes -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -NodeGroup AzureNodes -InitialNodeGrowth $InitialNodeGrowth -NodeGrowth $NodeGrowth
            }
        }
    }

    Else{
        Invoke-HPCClusterShrink -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler
    }
}
#A single scale run. If it needs to grow, it grows. If the grid is quiet, it shrinks. Not a loop!

Function Invoke-HPCClusterHybridScaleUp{
<# 
   .Synopsis 
    This function is a gradual HPC scale up - if there is a need for more nodes, it tries to expand on premise if it can. If there are no on-premise nodes, it will start any suitable Azure Nodes. It will not shutdown nodes.

   .Parameter Scheduler
    The scheduler used. Defaults to the one in use by the Environment

   .Parameter JobTemplates
    Specifies the names of the job templates to define the workload for which the nodes to grow. If not specified (the default value is @()), all active jobs are in scope for check.

   .Parameter CallQueueThreshold
    The number of queued calls required to set off a growth of Nodes.Default is 2000

   .Parameter GridMinsRemainingThreshold
    The time in minutes, of remaining Grid work. If this threshold is exceeded, more Nodes will be allocated. Default is 30

   .Parameter QueuedJobsThreshold
    How many Jobs need to be queued to trigger a Growth

   .Parameter InitialNodeGrowth
    The initial minimum number of nodes to grow if all the nodes in scope are NotDeployed or Stopped(Deallocated). Default is 10

   .Parameter NodeGrowth
    The amount of Nodes to grow if there are already some Nodes in scope allocated. Compare with $NumInitialNodesToGrow. Default is 5
    
   .Parameter Logging
    Whether the script creates a Log file or not - location determined by the LogFilePrefix. Default is True

   .Parameter LogFilePrefix
    Specifies the prefix name of the log file, you can include the path, by default the log will be in current working directory

   .Example 
    
    while(1) { Invoke-HPCClusterHybridScaler -CallQueueThreshold 50; Sleep 60 }

   .Notes 
    The prerequisites for running this script:
    1. Add the Azure nodes or the Azure VMs before running the script.
    2. This is not compatibile with the deprecated IAAS VMs. Use the Worker Roles.
    3. The HPC cluster should be running at least HPC Pack 2012 R2 Update 1
    4. This will use Groups to determine which Nodes should be grown

   .Link 
   www.excelian.com
#>

Param(
    [CmdletBinding()]
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
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

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $NodeGrowth=5,

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $CallQueueThreshold=2000,

    [Parameter (Mandatory=$False)]
    [bool] 
    $UndeployAzure=$True,

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

    [Parameter (Mandatory=$False)]
    [bool]
    $Logging=$False,

    [Parameter (Mandatory=$False)]
    [String]
    $LogFilePrefix="HPCClusterHybridScaleUp"

)

    Try{
        Add-PSSnapin Microsoft.hpc
    }
    Catch [System.Exception]{
        Write-LogError $Error.ToString() 
        $Error.Clear()
        Exit 
    }
    
    $HasGrown = $False
    $ActiveJobs = Get-HPCClusterActiveJobs -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -jobTemplates $JobTemplates
    $Count = Get-HPCClusterActiveJobCount

    Write-LogInfo "Jobs:$Count Scheduler:$Scheduler" -Logging $Logging -LogFilePrefix $LogFilePrefix 

    If($Count -ne 0){
    
        $Grow = Get-HpcClusterWorkload -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -jobTemplates $jobTemplates | Get-HPCClusterGrowCheck -Logging $Logging -LogFilePrefix $LogFilePrefix -CallQueueThreshold $CallQueueThreshold -ActiveJobs $ActiveJobs -NumOfQueuedJobsToGrowThreshold $NumOfQueuedJobsToGrowThreshold -GridMinsRemainingThreshold  $GridMinsRemainingThreshold
        
        If($Grow){
            $ToGrow = Get-HPCClusterNodesRequired -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes
            $InternalToGrow = $ToGrow | Where-Object  {$_.NodeState -contains "Offline" }
            $INTCount = $InternalToGrow.Count
            Write-LogInfo "InternalNodeCount:$INTCount" -Logging $Logging -LogFilePrefix $LogFilePrefix
            If($InternalToGrow.Count -ne 0){
                Write-LogInfo "Action:INTERNALGROWTH On-Premise Nodes Available"
                If($InternalGrow = Start-HPCClusterNodes -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -NodesToGrow $InternalToGrow -NodeGroup ComputeNodes -InitialNodeGrowth $InitialNodeGrowth -NodeGrowth $NodeGrowth -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates){
                    $HasGrown = $True
                }
            }
            Else{
                Write-LogInfo "Action:NOTHING No Suitable on-Premise Nodes Available"
                $AzureToGrow = $ToGrow | Where-Object  {($_.NodeState -contains "NotDeployed" -or $_.NodeState -contains "Offline") -and $_.Groups -match "AzureNodes"}
                $AZCount = $AzureToGrow.Count
                Write-LogInfo "AzureNodeCount:$AZCount" -Logging $Logging -LogFilePrefix $LogFilePrefix
                If($AzureToGrow.Count -ne 0){
                    Write-LogInfo "Action:GROWING Deploying Off-Premise Nodes"
                    If($AzureGrow = Start-HPCClusterNodes -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix -NodesToGrow $AzureToGrow -NodeGroup AzureNodes -InitialNodeGrowth $InitialNodeGrowth -NodeGrowth $NodeGrowth -ExcludedNodes $ExcludedNodes -ExcludedNodeTemplates $ExcludedNodeTemplates){
                        $HasGrown = $True
                    }
                    
                }
                Else{
                    Write-LogInfo "Action:NOTHING No Suitable Off-Premises Nodes Available" -Logging $Logging -LogFilePrefix $LogFilePrefix 
                }
            }
        }
        Else{
            Write-LogInfo "Action:NOGROWTH"
        }
    }
    Write-Output $HasGrown
}
#A Hybrid cluster scale up. First, it will attempt to use any available on premise nodes. If none are available, it will use the Azure Nodes. This only increases, it does not attempt to decrease. Not a loop!

Function Invoke-HPCClusterHybridShrink{
<#
    .Synopsis
    This determines whether shrinking is needed and if so Shrinks them.
    
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

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Example
    $GridMinsRemainingThreshold= 20
    
    .Notes
    Shrinks any Nodes not busy, including AzureNodes, although you can specify what is touched. 

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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

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

    [Parameter (Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [bool]
    $UndeployAzure = $True,

    [Parameter (Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
    [String[]] 
    $NodeTemplates
    )

    Try{
        Add-PSSnapin Microsoft.hpc
    }
    Catch [System.Exception]{
        Write-LogError $Error.ToString() 
        $Error.Clear()
        Exit 
    }

    $Shrink = Get-HPCClusterShrinkCheck -Scheduler $Scheduler -Logging $Logging -NodeGroup $NodeGroup -NodeTemplates $NodeTemplates -LogFilePrefix $LogFilePrefix  -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups
    If($Shrink.SHRINK){
        If($UndeployAzure -eq $True){
            $Shrink | Set-HPCClusterNodesUndeployedOrOffline -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix
        }
        Else{
            $Shrink | Set-HPCClusterNodesOffline -Scheduler $Scheduler -Logging $Logging -LogFilePrefix $LogFilePrefix
        }
    }
}
#A Hybrid cluster scale down. This will take any Nodes not acive offline

Function Invoke-HPCClusterHybridAutoScaler{
<# 
   .Synopsis 
    This function is a Hybrid HPC Cluster AutoScale check - if there is a need for more nodes, it expands Nodes that fit the criteria. If the grid is quiet, it will shut down nodes.

   .Parameter Scheduler
    The scheduler used. Defaults to the one in use by the Environment

    .Parameter jobTemplates
    Used to limit the search to a specific Job Template Name 

   .Parameter CallQueueThreshold
    The number of queued calls required to set off a growth of Nodes.Default is 2000

   .Parameter NumOfQueuedJobsToGrowThreshold
    The number of queued jobs required to set off a growth of Nodes.Default is 1

   .Parameter GridMinsRemainingThreshold
    The time in minutes, of remaining Grid work. If this threshold is exceeded, more Nodes will be allocated. Default is 30

   .Parameter InitialNodeGrowth
    The initial minimum number of nodes to grow if all the nodes in scope are NotDeployed or Stopped(Deallocated). Default is 10
   
   .Parameter SwitchInternalNodeTemplates
    Boolean. If True, it will attempt to switch Internal templates if required

   .Parameter UndeployAzure
   Boolean. If True, it will undeploy AzureNodes, otherwise it will just set them offline

   .Parameter NodeGrowth
    The amount of Nodes to grow if there are already some Nodes in scope allocated. Compare with $NumInitialNodesToGrow. Default is 5

    .Parameter ExcludedNodeTemplates
    Determines which Node Templates will not be considered as acitve/passive

    .Parameter ExcludedNodes
    Determines which Nodes will be excluded from the calculation

    .Parameter NodeTemplates
    Used to specify growing only a certain type of Nodes. 
    
   .Parameter Logging
    Whether the script creates a Log file or not - location determined by the LogFilePrefix. Default is True

   .Parameter LogFilePrefix
    Specifies the prefix name of the log file, you can include the path, by default the log will be in current working directory

   .Example 
    
    while(1) { Invoke-HPCClusterHybridAutoScaler -CallQueueThreshold 50; Sleep 60 }

   .Notes 
    The prerequisites for running this script:
    1. Add the Azure nodes or the Azure VMs before running the script.
    2. This is not compatibile with the deprecated IAAS VMs. Use the Worker Roles.
    3. The HPC cluster should be running at least HPC Pack 2012 R2 Update 1
    4. You can exclude Nodes, Templates or specify only certain templates to be included in the calculations

   .Link 
   www.excelian.com
#>

Param(
    [CmdletBinding()]

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
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

    [Parameter (Mandatory=$False)]
    [ValidateRange(0,[Int]::MaxValue)]
    [Int] 
    $NodeGrowth=5,

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

    [Parameter (Mandatory=$False)]
    [bool]
    $Logging=$False,

    [Parameter (Mandatory=$False)]
    [String]
    $LogFilePrefix="HPCClusterSimpleAutoScaler"

)

    Try{
        Add-PSSnapin Microsoft.hpc
    }
    Catch [System.Exception]{
        Write-LogError $Error
        $Error.Clear()
        Exit 
    }

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
        
        If($Growth -eq $False -and $SwitchInternalNodeTemplates -eq $True){
           
            If(Invoke-HPCClusterSwitchNodesToRequiredTemplate -NodeTemplates $NodeTemplates -NodeGroup ComputeNodes -JobTemplates $jobTemplates -Logging $logging -LogFilePrefix $LogFilePrefix -Scheduler $Scheduler -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes){
                Write-LogInfo "Action:TemplateSwitched"
            }
            Else{
                Write-LogInfo "Action:NOTHING Unable to migrate templates"
            }
        }
    }

    Else{
        Write-LogInfo "Action:Nothing No Growth Required"
        Invoke-HPCClusterHybridShrink -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -UndeployAzure $UndeployAzure -NodeTemplates $NodeTemplates
    }
}
#A single full-scale run. If it needs to grow, it grows. If the grid is quiet, it shrinks - detects which Nodes are required. It can also switch templates!

Function Invoke-HPCClusterSwitchNodesToRequiredTemplate{
<#
    .Synopsis
    This swaps offline nodes to Templates that are in demand. It assumes that the groups are being used as discriminators. Designed for ComputeNodes rather than AzureNodes (will not take UnDeployed Nodes). 
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable

    .Parameter Logging
    Boolean whether or not to create a log or just display host output
    
    .Parameter NodesToGrow
    A collection of Nodes you want to grow. Should be recieved from Remove-HPCClusterGroups if using groups as discriminators. 

    .Example
    Invoke-HPCClusterSwitchNodesToRequiredTemplate
    
    .Notes
    Once given a collection of Nodes, will discover which groups need assigning and assign them.

    .Link
    www.excelian.com
#>
    [CmdletBinding()]
    Param(
    [Parameter (Mandatory=$False)]
    [string[]] 
    $NodeTemplates=@(),

    [Parameter (Mandatory=$False)]
    [string[]] 
    $NodeGroup=@("ComputeNodes"),

    [Parameter (Mandatory=$False)]
    [string[]] 
    $JobTemplates=@(),

    [Parameter (Mandatory=$False)]
    [bool]
    $Logging=$False,

    [Parameter (Mandatory=$False)]
    [String]
    $LogFilePrefix,

    [Parameter (Mandatory=$False)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter (Mandatory=$False)]
    [string[]]
    $ExcludedGroups = @("InternalCloudNodes","SOPHIS"),

    [Parameter (Mandatory=$False)]
    [string[]]
    $ExcludedNodeTemplates=@(),

    [Parameter (Mandatory=$False)]
    [string[]]
    $ExcludedNodes=@()
    )
    $HasSwitched = $False

    $Count = Get-HPCClusterActiveJobCount -LogFilePrefix $LogFilePrefix -Scheduler $Scheduler -Logging $Logging -JobTemplates $JobTemplates
    If($Count -ne 0){
        $CurrentState = Get-HPCClusterStatus -LogFilePrefix $LogFilePrefix -Logging $Logging -Scheduler $Scheduler -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups -jobTemplates $JobTemplates
        If($CurrentState.IdleNodes.Count -ne 0 ){
        
            $ReadyCheck = Get-HPCClusterIdleReadyNodes -Logging $Logging -LogFilePrefix $LogFilePrefix -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -Scheduler $Scheduler
            $ChangeCheck = Get-HPCClusterIdleDifferentNodes -Logging $Logging -LogFilePrefix $LogFilePrefix -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -NodeGroup $NodeGroup -Scheduler $Scheduler
            If($ReadyCheck){
                Write-LogInfo "Required Nodes Available"
            }
            ElseIf($ChangeCheck){
                $Stripped = Remove-HPCClusterGroups -ExcludedGroups $ExcludedGroups -Logging $Logging -LogFilePrefix $LogFilePrefix -NodesToGrow $ChangeCheck -Scheduler $Scheduler
                Convert-HPCClusterTemplate -Logging $Logging -LogFilePrefix $LogFilePrefix -NodesToGrow $Stripped -Scheduler $Scheduler -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups -ExcludedNodeTemplates $ExcludedNodeTemplates
                $HasSwitched = $True
            }
            Else{
                Write-LogInfo "Action:NOTHING No Idle Nodes available for movement"
            }
        }
        Else{
            Write-LogInfo "Action:NOTHING No Idle Nodes available"
        }
    }
    Else{
        Write-LogInfo "Action:NOTHING No Active jobs"
    }
    Write-Output $HasSwitched
}
#A single run that confirms if a Node Template has unused capacity - and if it does switches the Templates.

Function Optimize-HPCCluster{
<#
    .Synopsis
    This determines whether the Grid is currently evenly balanced.
    
    .Parameter LogFilePrefix
    Determines the prefixed log name

    .Parameter Logging
    Boolean whether or not to create a log or just display host output

    .Parameter Scheduler
    Determines the scheduler used - defaults to the environment variable
    
    .Parameter PercentageTolerance
    How much percentage over or under the perfect balance percentage before the Grid is deemed unbalanced. If not provided, 

    .Parameter ExcludedNodeTemplates
    Determines which Node templates will be excluded from the calculation

    .Parameter ExcludedNodeS
    Determines which Nodes will be excluded from the calculation

    .Parameter ExcludedGroups
    This function excludes groups 1-9 as they are descripive (ComputeNodes,AzureNodes). If you have other descriptive groups, excluding them means that the script will not treat them as active/passive for later calculation.

    .Example
    Optimize-HPCCluster -Logging $False -ExcludedGroups SlowNodes
        
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

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $Scheduler = $env:CCP_SCHEDULER,

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
        $Jobs = Get-HPCClusterActiveJobs -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging
        $JCount = $Jobs.Count
        $Balanced = $True

        If($JCount -ne 0){
            $State = Get-HPCClusterStatus -Scheduler $Scheduler -LogFilePrefix $LogFilePrefix -Logging $Logging -ExcludedNodeTemplates $ExcludedNodeTemplates -ExcludedNodes $ExcludedNodes -ExcludedGroups $ExcludedGroups

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
            
                $Nodes = Get-HpcNode -Scheduler $Scheduler -Name $State.BusyNodes.split(",") | sort -Property ProcessorCores -Descending

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

                Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:PREPARATION NodesCanMove:$NodesCanMoveCount CoresCanMove:$CoresCanMove BalancedPercentage:$BalancedPercentage PercentageTolerance:$PercentageTolerance UpperThreshold:$UpperPercThreshold LowerThreshold:$LowerPercThreshold"  

                <#
                #Commented out as it duplicates the previous section
                If($NodesCanMoveCount -gt $BusyTempCount){

                    ForEach($Key in $TemplateNodeMap.GetEnumerator()){

                        $Perc = $($Key.Value) / $TotalNodes * 100
                        Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC NodeTemplate:$($Key.Name) ExtraNodes:$($key.Value) Percentage:$Perc"
            
                        If($Perc -le $UpperPercThreshold -and $Perc -ge $LowerPercThreshold ){
                            Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC NodeTemplate:$($Key.Name) NodesBalanced:$NodesBalanced"
                        }

                        ElseIf($Perc -gt $UpperPercThreshold){
                            $NodesBalanced = $False
                            Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC NodeTemplate:$($Key.Name) NodesBalanced:$NodesBalanced"
                            $NodesToMove += Get-HpcNode -Scheduler $Scheduler -Name $State.BusyNodes.split(",") -TemplateName $($Key.Name)| Sort ProcessorCores | Select-Object -First $BusyTempCount
                        }
          
                        Else{
                        $NodesBalanced = $False
                        Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC NodeTemplate:$($Key.Name) NodesBalanced:$NodesBalanced"
                        }
                }
            }

                Else{
                Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:NODECALC Msg:`"Insufficient Nodes to Move`""
            }

            #>
                ForEach($Key in $TemplateCoreMap.GetEnumerator()){
                $Perc = $($Key.Value) / $TotalCores * 100
                Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:CORECALC NodeTemplate:$($Key.Name) ExtraCores:$($key.Value) Percentage:$Perc"
                
                If($Perc -le $UpperPercThreshold -and $Perc -ge $LowerPercThreshold){
                            Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:CORECALC NodeTemplate:$($Key.Name) CoresBalanced:$CoresBalanced"
                }
                
                ElseIf($Perc -gt $UpperPercThreshold){
                    $NodesBalanced = $False
                    Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:CORECALC NodeTemplate:$($Key.Name) CoresBalanced:$NodesBalanced"

                    $NodesToMove += Get-HpcNode -Scheduler $Scheduler -Name $State.BusyNodes.split(",") -TemplateName $($Key.Name)| Sort ProcessorCores | Select-Object -First $BusyTempCount
                }

                Else{
                    $CoresBalanced = $False
                    Write-LogInfo -Message "Action:CORECALC NodeTemplate:$($Key.Name) CoresBalanced:$CoresBalanced"
                }
            }

                If($NodesBalanced -eq $False -or $CoresBalanced -eq $False){
                Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:REBALANCE Msg:`"Grid Balance out of Percentage Tolerance`""

                Set-HpcNodeState -Scheduler $Scheduler -State offline -Force -Node $NodesToMove -ErrorAction SilentlyContinue    
                }
            }
            Else{
                Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -message "Action:Silent Msg:`"Only one active Node Template`"" 
            }
        }
        Else{
            Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:SILENT Msg:`"No Active Jobs to Balance`""
        }

        $NodesToGrow = @() 
        ForEach($Node in $NodesToMove){
            If($NodesToGrow -notcontains $Node){
                $NodesToGrow += $Node
                }
            }
        Write-LogInfo -LogFilePrefix $LogFilePrefix -Logging $Logging -Message "Action:COMPLETE" 
        Write-Output $NodesToGrow
        }
    Catch{
        Write-LogError -LogFilePrefix $LogFilePrefix -Logging $Logging -message $_.exception.message
        $error.clear()
        }
}
#Yes... this doesn't quite work. In theory, if the Cluster is overworked, it's meant to take an even amount of Nodes offline, and then let the cluster balance itself using Convert-HPCClusterTemplate....
#endregion

#region Reporting
Function Get-HPCClusterJobHistoryOutput{
    <#
        .Synopsis
        This function get's the previous history of the HPC Cluster Jobs

        .Parameter LastKnownPositionFile
        Name of the file that records the tiem the records were last collected. Prevents duplicate data. If not present, goes for the standard loop 

        .PositionFolder
        The directory where the LastKnownPositionFile is stored - so you can locate it where you wish

        .Parameter Duration
        Choose the frequency of collections in seconds. Minimum 5400 seconds
        
        .Parameter Scheduler
        Determines the scheduler used - defaults to the environment variable
        
        .Parameter Delimiter
        Choose the string to delimit the output with

        .Example
        Get-HPCClusterJobHistoryOutput -Delimiter ","
        .Notes

        .Link
        www.excelian.com
    #>    

        [CmdletBinding()]
        Param(

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $Scheduler = $env:CCP_SCHEDULER,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [String]
        $PositionFolder = "..\HPCAppRecords_DONOTDELETE\$Scheduler",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $LastKnownPositionFile = ".\JobHistory_LastKnownPosition",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [int]
        [ValidateRange(5400, [int]::MaxValue)]
        $Duration = "5400",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [int]
        [ValidateRange(1, [int]::MaxValue)]
        $InitialCollection = "90",

        [Parameter(Mandatory=$False)]
        $Delimiter="|"

        )

        Try{
            $ErrorActionPreference = "SilentlyContinue"
            $WarningPreference = "SilentlyContinue"
            Add-PSSnapIn Microsoft.HPC;
        }
        Catch [System.Exception]{
            Write-Error $Error.ToString()
            $Error.Clear()
            Break
        }

        $duration = 5400

        If(Test-Path $PositionFolder){Write-Verbose "$PositionFolder Exists"}
        Else{$X = New-Item $PositionFolder -Type Directory}

        $LastKnownPositionFile = $PositionFolder + "\" + $LastKnownPositionFile

        If($SINCE = Get-Content $LastKnownPositionFile){
            Write-Verbose "$LastKnownPositionFile Exists"
            Remove-Item $LastKnownPositionFile
        }
        Else{
            Write-Verbose "First Time Run"
            $SINCE = (Get-Date).AddDays(-90)
        }
        
        $NOW = (Get-Date).addSeconds(-1 * $duration)
        $NOW = $NOW.ToString("dd/MM/yyyy HH:mm:ss")
	    Write-Verbose "SinceDate $SINCE"  
        Write-Verbose "NowDate $NOW"
        
        Try{
            Write-Verbose "Collection"
            Get-HPCJobHistory -Scheduler $Scheduler -StartDate $SINCE -EndDate $NOW #-verbose
        }
        Catch [System.Exception]{
            Write-Error $Error.ToString()
            $Error.Clear()
        }

        Write-Output $NOW >> $LastKnownPositionFile
	    Write-Verbose "LastKnownPositionFileUpdated"

}
#Returns Job History Objects

Function Export-HPCClusterFullJobHistory{
<#
    .Synopsis
    This collects the recent Job History and adds data from the SQL database to give accurate task times. 
    
    .Parameter PositionFolder
    Where the timestamp record should be stored

    .Parameter LastKnownPositionFile
    The name of the timestamp record

    .Parameter Delimiter
    What should the delimiter be

    .Parameter Scheduler
    Which scheduler should be tapped for the history

    .Example
    Export-HPCClusterFullJobHistory -LastKnownPositionFile "Output.txt"
#>
        [CmdletBinding()]
        Param(

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $Scheduler = $env:CCP_SCHEDULER,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [String]
        $PositionFolder = "..\HPCAppRecords_DONOTDELETE\$Scheduler",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]
        $LastKnownPositionFile = ".\JobHistory_LastKnownPosition",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [int]
        [ValidateRange(5400, [int]::MaxValue)]
        $Duration = "5400",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [int]
        [ValidateRange(1, [int]::MaxValue)]
        $InitialCollection = "90",

        [Parameter(Mandatory=$False)]
        $Delimiter="|"

        )
   
    Try{
        Import-Module -Name .\MicrosoftHPCServerTools.psm1 -ErrorAction SilentlyContinue -Force
        Add-PSSnapin Microsoft.hpc
        Set-Culture EN-GB
    }

    Catch [System.Exception]{
        Write-Error $Error.ToString()
        $Error.Clear()
    }

    $Output = Get-HPCClusterJobHistoryOutput -Scheduler $Scheduler -LastKnownPositionFile $LastKnownPositionFile -PositionFolder $PositionFolder -Delimiter $Delimiter #-verbose

    If($Output.Count -ne 0){
        
        Try{
            $IdString = ""
            ForEach($Job in $Output){
                If($Job.JobId -ne $null){
                    $Id = $Job.JobID.ToString()
                    $IdString += "$Id,"
                }
            }
        }
        Catch [System.Exception] {

        }

        If($IdString.Length -gt 0){
            $IdString = $IdString.SubString(0,$IdString.Length-1)
            $TaskTimes = Get-HPCJobTaskTime -ParentJobs $IdString
            

            ForEach($Job in $Output){
                If($Job.JobId -ne $null){
                    $Array = @()
                    $Id = $Job.JobID.ToString()
                    $Record = $TaskTimes.Select("ParentJobID=$Id")
                    $JobJSON = $Job | ConvertTo-Json -Compress
                    $JobJSON = $JobJSON.Replace("{","").Replace("}",",")
                    $Array += $JobJSON
                    $Array += [char]34+"TotalTaskSeconds"+[char]34+":"+[char]34+$Record.Seconds+[char]34+","
                    $JSON = "{"+$Array+"}"
                    $FinalObject = $JSON.Replace(",}","}") | ConvertFrom-Json
                    $FinalObject
                }
            }
        }
    }
    Else{
        Write-Verbose "No Job History Found"
    }
}
#Returns Job History with added SQL data from HPCJobTaskTime

Function Get-HPCJobTaskTime{
    <#
        .Synopsis
        This collects the time in Seconds for the sum of all tasks by Job ID

        .Parameter Scheduler
        Determines the scheduler used - defaults to the environment variable
    
        .Parameter ParentJobs
        Must be a single string that contains all the JobIDs you want

        .Example
        Get-HPCJobTaskTime -ParentJobs "1000,1002"
    
        .Notes
        Used to determine what the current load is - pass it to Get-HPCClusterGrowCheck

        .Link
        www.excelian.com
    #>
    [CmdletBinding()]
    Param(

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [String]
    $ParentJobs

    )

    Try{
        Add-PSSnapin Microsoft.hpc
        $Registry = Get-HPCClusterRegistry -Scheduler $Scheduler
        $Server = $Registry.SchedulerDBServerName
        $DBName = "HPCScheduler"
    }
    Catch [System.Exception]{
        Write-LogError $Error.ToString()
    }

    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server = $Server; Database = $DBName;Integrated Security=True"

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.CommandText = "Select ParentJobID,ISNULL(SUM(DATEDIFF(SECOND,StartTime,EndTime)),0) as Seconds from task where ParentJobId in ($ParentJobs) group by ParentJobID order by ParentJobID"
    $cmd.Connection = $conn

    Try{
        $conn.Open()
    }
    Catch [System.Exception]{
        Write-LogError $Error.ToString()
    }

    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter

    $SqlAdapter.SelectCommand = $cmd

    $DataSet = New-Object System.Data.DataSet

    $X = $SqlAdapter.Fill($DataSet)

    $conn.Close()

    $Output = $DataSet.Tables

    Write-Output $Output

}
#Returns DataSet - JobID and Total Seconds

Function Get-HPCCoreUtilisation{
    <#
        .Synopsis
        This collects the time in Seconds for the sum of all tasks by Job ID

        .Parameter Scheduler
        Determines the scheduler used - defaults to the environment variable
    
        .Parameter PositionFolder
        Where the timestamp record should be stored

        .Parameter LastKnownPositionFile
        The name of the timestamp record

        .OnlyCollectOnce
        Boolean. If True, it will track what data has been extarcted, only collecting new data. Use False to extract all data for your own purposes. 

        .Example
        Get-HPCJobTaskTime -ParentJobs "1000,1002"
    
        .Notes
        Used to determine what the current load is - pass it to Get-HPCClusterGrowCheck

        .Link
        www.excelian.com
    #>
    [CmdletBinding()]
    Param(

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String]
    $Scheduler = $env:CCP_SCHEDULER,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String]
    $PositionFolder = "..\HPCAppRecords_DONOTDELETE\$Scheduler",

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [bool]
    $OnlyCollectOnce = $True,

    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [string]
    $LastKnownPositionFile = ".\ClusterUsage_LastKnownPosition"

    )

    Try{
        Add-PSSnapin Microsoft.hpc
        $Registry = Get-HPCClusterRegistry -Scheduler $Scheduler
        $Server = $Registry.ReportingDBServerName
        $DBName = "HPCReporting"
        $SINCE = $null
        Set-Culture EN-GB
    }
    Catch [Exception]{
        Write-LogError $Error.ToString()
    }
                
    #Checking what dates we need to run
    If($OnlyCollectOnce -eq $True){

        If(Test-Path $PositionFolder){Write-Verbose "$PositionFolder Exists"}
        Else{New-Item $PositionFolder -Type Directory }

        $LastKnownPositionFile = $PositionFolder + "\" + $LastKnownPositionFile

        If($Since = Get-Content $LastKnownPositionFile -ErrorAction SilentlyContinue){
            Write-Verbose "$LastKnownPositionFile Exists"
            Write-Verbose "Since Date $Since"
            Remove-Item $LastKnownPositionFile
        }
        Else{
            Write-Verbose "First Time Run"
        }
    
        $Now = (Get-Date).AddDays(-1)  
        $Now = $Now.ToString("yyyy/MM/dd")
	    Write-Verbose "NowDate $Now"

    }
    if($Since -eq $null){
        $Filter = " N.NumberOfCores IS NOT NULL"
    }
    else{
        $Filter = "[Date] > Convert(Date,'$Since') AND N.NumberOfCores IS NOT NULL" 
    }

    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server = $Server; Database = $DBName;Integrated Security=True"

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    
    $String = "SELECT Convert(Date,[Date]) as Date,
                        N.NodeName,
                        N.NumberOfCores, 
                        V.UtilizedTime AS TotalUtilised, 
                        V.UtilizedTime / N.NumberOfCores as UtilisedByCore,
                        V.CoreAvailableTime AS TotalAvailable, 
                        V.CoreAvailableTime / N.NumberOfCores AS AvailableByCore,
                        V.CoreTotalTime, 
                        V.CoreTotalTime / N.NumberOfCores AS TotalByCore 

                        FROM HpcReportingView.DailyNodeStatView V 

                        INNER JOIN Node N ON N.NodeName = V.NodeName 
                        WHERE $Filter"

    
    $cmd.CommandText = $String
    $cmd.Connection = $conn

    Try{
        $conn.Open()
    }
    Catch [System.Exception]{
        Write-LogError $Error.ToString()
    }

    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter

    $SqlAdapter.SelectCommand = $cmd

    $DataSet = New-Object System.Data.DataSet

    $X = $SqlAdapter.Fill($DataSet)

    $conn.Close()

    $Output = $DataSet.Tables

    Write-Output $Output
    If($OnlyCollectOnce -eq $True) {Write-Output $NOW >> $LastKnownPositionFile} 

}
#Returns DataSet - Containing Core Utilisation Details

Function ConvertTo-LogscapeJSON{
        <#
            .Synopsis
            This converts an object to a Logscape compatibile JSON String, plus a timestamp
        
            .Parameter Input
            The Object needing conversion

            .Parameter NoDate
            Remove Timestamp - Boolean

            .Example
            Get-HpcClusterOverview | ConvertTo-LogscapeJSON
            .Notes

            .Link
            www.excelian.com
        #>    
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
    [System.Object]
    $Input,

    [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
    [bool]
    $Timestamp = $True
    )

    If($Input.Count -ne 0){
        $STAMP = Get-Date -Format "yyyy/MM/dd HH:mm:ss zzz"
        $Input = $Input | ConvertTo-Json -Compress

        $OutString = $Input.Replace("{","{ ").Replace("}"," }").Replace("\/","")
        $OutString = $OutString -Replace ":(\d+),",':"$1",'
        $OutString = $OutString -Replace ":(\d+) }",':"$1" }'

        $Collection = $OutString | Select-String -AllMatches -Pattern 'Date\((\d+)\)' |Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value

        $Map = @{}

        ForEach($Element in $Collection){
            $Number = $Element.TrimEnd(")").TrimStart("Date(")
            $RequiredDate = ConvertFrom-UnixTime $Number
            $NewDate = Get-Date -Date $RequiredDate -Format "yyyy/MM/dd HH:mm:ss"
            $NewKey = $Element.ToString()
            $NewValue = $NewDate.ToString()

            Try{
            $Map.Add($NewKey,$NewValue)
            }
            Catch [System.ArgumentException] {
                Write-Verbose "$NewKey already added"
            } 
        }

        ForEach($Target in $Map.GetEnumerator()){
            $OutString = $OutString.Replace($($Target.Name),$($Target.Value))
        }

        If($Timestamp -eq $True){
            $OutString = $STAMP + " " + $OutString
        }

        Write-Output $OutString

    }
}
#Converts to Logscape compatible JSON

Function ConvertTo-LogscapeCSV{
    <#
        .Synopsis
        This converts an object to a Logscape compatibile CSV String, plus a timestamp
        
        .Parameter Input
        The Object needing conversion

        .Parameter NoDate
        If True, strips the timestamp from the front

        .Parameter AddHeaders
        A boolean, defaults to false. Standard Powershell CSV export pumps out headers each time - unsuitable for Logging purposes. Leave as false unless you want them!

        .Example
        Get-HpcClusterOverview | ConvertTo-LogscapeJSON
        .Notes

        .Link
        www.excelian.com
    #>    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [System.Object]
        $Input,

        [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
        [bool]
        $TimeStamp = $True,

        [Parameter(Mandatory=$False)]
        [string]
        $Delimiter = ",",

        [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
        [bool]
        $AddHeaders=$False
        )
    If($Input -ne $Null){
        $STAMP = Get-Date -Format "yyyy/MM/dd HH:mm:ss zzz"
        $Input = $Input | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter
        If($AddHeaders -eq $False){
            $Input = $Input | select -Skip 1
        }
    
        If($Timestamp -eq $True){
            $OutString = $STAMP + $Delimiter + $Input.Replace('"',"")
        }
        Else{
            $OutString = $Input.Replace('"',"")
        }
        Write-Output $OutString 
    }
}
#Converts to Logscape compatible CSV

Function ConvertFrom-UnixTime{
    <#
        .Synopsis
        This converts a Unix time uinto a Powershell Date object
        
        .Parameter UnixTime
        The Unix Time needing conversion

        .Example
        Convert-From-UnixTime
        .Notes

        .Link
        www.excelian.com
    #>    

    [CmdletBinding()]
    
    Param(
    [Parameter (Mandatory=$True,Position=1,ValueFromPipeline=$True)] 
    [Long]
    $UnixTime
    )

    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $ReadableDate = $origin.AddMilliseconds($UnixTime)

    Write-Output $ReadableDate
}
#endregion
