Add-PsSnapin microsoft.hpc

While (1){
    $NodesToTurnOff = Get-HpcNode -HealthState Error -State Online -ErrorAction SilentlyContinue
    
    If($NodesToTurnOff.count -gt 1){Set-HpcNodeState -State offline -Node $NodesToTurnOff -force}
    Else{ Write-Output "No nodes to turn off"}

    $NodesToTurnOn = Get-HpcNode -HealthState Ok -State Offline -GroupName ComputeNodes -ErrorAction SilentlyContinue

    If($NodesToTurnOn.count -gt 1){Set-HpcNodeState -State online -Node $NodesToTurnOn }
    Else{ Write-Output "No nodes to turn on"}

    sleep 30 
}