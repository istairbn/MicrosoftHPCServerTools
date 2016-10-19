[Cmdletbinding()]
Param(
[Parameter(Mandatory=$True)]
[ValidateScript({Test-Path $_})]
[string]
$ParameterScript = ".\MapParams.ps1",

[Parameter(Mandatory=$True)]
[ValidateScript({Test-Path $_})]
[string]
$MainScript = ".\ParamMap.ps1",

[Parameter(Mandatory=$False)]
[int]
$HoursUntilServiceRestarts = 2,

[Parameter(Mandatory=$False)]
[int]
$Sleep = 60
)
$elapsed = [System.Diagnostics.Stopwatch]::StartNew() 
$StartItem = Get-Item $ParameterScript
$CurrentItem = Get-Item $ParameterScript

While(($StartItem.LastWriteTimeUtc -eq $CurrentItem.LastWriteTimeUtc) -and ($elapsed.Elapsed.Hours -lt $HoursUntilServiceRestarts)){

    . $ParameterScript

    . $MainScript @Parms 
    
    sleep $sleep 
    $CurrentItem = Get-Item $ParameterScript

}