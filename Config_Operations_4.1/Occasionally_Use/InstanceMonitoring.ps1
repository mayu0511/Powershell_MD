Clear-Host
$Getresult = $null
$State = "pending","shutting-down","terminated","stopping","stopped"
$ServersType = "*cciss*", "*ccew**", "ccsvc", "*ccaut*", "cctnp", "*ccawf*", "*ccsrc*", "*ccsnk*", "*ccbat*", "*ccweb*", "*ccwcf*"
Foreach ($SplitState in $State){
Foreach ($ServerType  in $ServersType){
$Getresult += aws ec2 describe-instances --query "Reservations[*].Instances[*].{IPAddress:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=$SplitState" "Name=tag:Name,Values='$ServerType'"  --output table
}}
if ($Getresult -eq $null) {Write-Host -ForegroundColor Green "SUCCESS:: No Servers found" }
else{Write-Host -ForegroundColor red "ERROR:: Some Servers found"
$Getresult
}
Clear-Variable ServersType
Clear-Variable State
Clear-Variable SplitState
