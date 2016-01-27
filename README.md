# MicrosoftHPCServerTools
A HPC Server 2012 R2 Powershell Module that contains Functions related to automating any deployment: internal, hybrid and Azure.

There are functions for tracking the current workload, stripping groups, growing and shrinking resources. 

It includes advanced autoscaling functionality as well as functions for swapping Internal Nodes between templates. All functions accept the Scheduler Parameter - meaning you can remotely control Schedulers. All functions are fully documented, use Get-Help followed by the Function name to get the list of parameters. 

Autoscaling: 
If you have the simplest of Clusters (1 App, no cross-dependencies) just run the following Powershell:
```powershell
code
While (1){Invoke-HPCClusterSimpleAutoscaler;sleep 60}
```
If you have a more complex Cluster, try this:

#While (1){Invoke-HPClusterHybridAutoscaler - SwitchInternalNodeTemplates $False; sleep 60}

Further examples will be added. 

Logging:
 - Get-LogFileName
 - Write-LogInfo
 - Write-LogWarning
 - Write-LogError

These functions are used throughout to control the logging of the various components. By and large, you can leave these alone - but if you combine scripts it can be helpful to use consistent logging. 

Cluster Information
  - Get-HPCClusterActiveJobs : Returns the current running and queued Job Objects, a building block for autoscaling. Filterable
  - Get-HPCClusterJobCount : Returns an Int count of running and queued Jobs. Not filtered 
  - Get-HPCClusterWorkload : Returns a custom object detailing your current use of the Grid in terms of calls and cores.#
  - Get-HPCClusterElements : Returns a custom object detailing available services, templates etc
  - Get-HPCClusterNodeDetail : Returns Stateful and Static info about Nodes - saves making 2 calls. Use Where-Object to filter.
  - Get-HPCClusterStatus : Returns an object detailing the current utilisation status of Node Objects, Templates and Groups
  - Get-HPCClusterRegistry : Returns the Registry entries such as reporting database location.
  - Get-HPCClusterJobRequirements : Returns Groups,Job Templates and Pools required - used for autoscaling
  - Sync-HPCClusterJobAndNodeTemplates : Returns a HashMap of Job and Default Node Templates - Required for Internal scaling
  - Export-HPCClusterDefaultGroupFromTemplate : Returns a HashMap of Job and Node Templates (Underlying function for Sync - Use that instead)

These functions all collate information for commandline use. Some of them are mainly designed for implementation in later functions, and may appear of little use to an Administrator. The most useful will be ClusterStatus and Workload - these can confirm the true state of the Grid.

Cluster Growth
  - Get-HPCClusterGrowCheck : Returns a Boolean - if True the cluster needs more resources. The limits determining the resource limits are set as parameters. You can set it to queued jobs, call queue or grid minutes remaining. 
  - Get-HPCClusterNodesRequired : Returns all possible Node Objects that could currently work on the Jobs available.
  - Start-HPCClusterNodes : Turns Internal Nodes online and Deploys Azure Nodes. If you provide this function with Node Objects (i.e. pipe in the output from Get-ClusterNodesRequired) then it will select it's target nodes from that pool. If no nodes are provided, this function will just turn on Nodes that it can. If there are no nodes active currently, it uses the "Initial Node Growth" amount. Otherwise, it will grow by the NodeGrowth amount. Returns a boolean if at least one Node is successfully activated. It will always use Internal Nodes before considering Azure. 

These three functions form the heart of an automatic scaling. They have multiple input parameters (use Powershell Help to pull the documentation out) allowing you to control which Nodes are included in the Growth consideration. 

Cluster Groups
  - Set-HPCClusterOneNodePerGroup - This ensures that at every group has at least one Node active. If using Groups as discriminators, this will ensure that work will always start. Returns nothing.
  - Remove-HPCClusterGroups - Used as part of the Internal scaling. This strips Nodes of their groups (you can exclude Groups from this process). 

These functions don't fit neatly in any other section because they assume you are using Groups for discriminators. 

Cluster Shrink
  - Get-HPCClusterShrinkCheck : Returns a custom object containing inactive node ojects, inactive node names and aboolean as to whether there are inactive nodes. Of course, this doesn't mean there is no work forthcoming, but this tells you what is currently quiet.
  - Set-HPCClusterNodesOffline : Given a set of Nodes, this turns Nodes offline ONLY. It does not Undeploy AzureNodes. Returns a boolean if at least one Node has been set offline.
  - Set-HPCClusterNodesUndeployedOrOffline : Given a set of nodes, this will undeploy Azure Nodes and set Internal Nodes offline. Returns a boolean if at least one Node has been set offline.

These functions are fairly straightforward, allowing you to automate the undeployment of Azure Nodes. This allows you to minimise expenditure. 

Cluster Balancing

  - Convert-HPCClusterTemplate : This takes offline Internal Nodes and converts them from Node Templates that are not in demand into Templates that are in demand. This is useful when different templates are required for different applications (i.e. you use Maintain to ensure the machine is prepared to accept work). If more than one Template is in demand, it will balance between them. Returns a Boolean for success state.
  - Get-HPCClusterIdleReadyNodes : Returns Node Objects of any Nodes that are Offline that have Busy Templates (i.e. offline nodes that could accept work)
  - Get-HPCClusterIdleDifferentNodes : Returns Node Objects of any Nodes that are Offline where the Node Template is not in use (i.e. these Nodes are suitable targets for Convert-HPCClusterTemplate. Note, if you are using this, you should ensure that
  - Set-HPCClusterOneNodePerGroup is run first - otherwise you may end up robbing a Template of all it's nodes. 
  - Invoke-HPCClusterSimpleAutoScaler : A single run through the functions. If there is work to do and Nodes free, it will turn them off. If there are Nodes idle, it will turn them off. Not a loop, does not check Requirements or change Templates. For the simplest of Clusters that require just to grow as demand increases.
  - Invoke-HPCClusterHybridScaleUp : A function that checks if the Cluster needs to Grow. This will only activate Nodes that can accept work (as opposed to Simple which simply expands the Grid). It will scale Internal Nodes first, but if the requirements are still not met it will try to grow Azure. Not a loop, doesn't shrink, just attempts to grow the cluster.
  - Invoke-HPCClusterHybridShrink : A function that attempts to shrink the Grid if possible. You can define whether or not it undeploys Azure. Not a loop, a single run.
  - Invoke-HPCClusterSwitchNodesToRequiredTemplate : A function that checks Internal Nodes to see if there is unutilised Internal Capacity. And if there is, it switches those Nodes on. If there are Internal Nodes with the incorrect Template, it will swap the Templates over and then deploy them. A single run, not a loop
  - Invoke-HPCClusterHybridAutoScaler : A function that combines the previous three Invoke Functions. It checks to scale up, then checks if it needs to scale down and can shuffle internal templates around. There are multiple parameters (detailed in the help of the function) that allow you customise whether or not the internal Nodes are moved. 
  - Optimize-HPCCluster : Not finished yet. Intended to rebalance Internal Only Grids (Azure renders it rather unecessary). 

These functions deal with automatic scaling of the Grid. As you can see, the Invoke- functions do not loop or repeat - however making them do so in your own script is relatively trivial - see the examples for details. 

Cluster Reporting
  - Get-HPCClusterJobHistoryOutput : Returns JobHistory Objects. Places a record file to remember when it last collected data. If it's never run before, it will collect the last 90 days. If it has run previously, it will only collect the new data. Can be set to collect the same information each time. 
  - Export-HPCClusterFullJobHistory : Returns JobHistory with added SQL data from Get-HPCJobTaskTime. 
  - Get-HPCJobTaskTime : Returns an SQL Dataset of JobID and Total Task Time
  - Get-HPCCoreUtilisation : Returns an SQL dataset of Core Utilisation
  - ConvertTo-LogscapeJSON : Converts any Powershell Object into Logscape Compatible JSON = strips unecessary quotation marks, prepends a timestamp
  - ConvertTo-LogscapeCSV : Returns a CSV with a time stamp (optional),  optional headers and allows you to pick your delimiter
  - ConvertFrom-UnixTime : Converts UnixTime to Powershell date, used to improve the ConvertTo-LogscapeJSON. 
