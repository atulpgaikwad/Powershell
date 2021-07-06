# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber

$ruleName = "Atul"
$ruleDesc = "Allow RDP from Public IP"
$rulePort = 3389

$myIp = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
Write-Output("IP v4 - "+$myIp)
 
function AddOrUpdateRDPRecord {
	Process {	
		$nsg = Get-AzNetworkSecurityGroup -Name $_.Name 
		# Update the existing rule with the new IP address
		Set-AzNetworkSecurityRuleConfig `
			-NetworkSecurityGroup $nsg `
			-Name $ruleName `
			-Description $ruleDesc `
			-Access Allow `
			-Protocol TCP `
			-Direction Inbound `
			-Priority 1180 `
			-SourceAddressPrefix $myIp `
			-SourcePortRange * `
			-DestinationAddressPrefix * `
			-DestinationPortRange $rulePort 
		
        # Save changes to the NSG
		$nsg | Set-AzNetworkSecurityGroup
		Write-Output("Process Network Group - "+$nsg.Name)
    }
}

# Connect-AzAccount
Get-AzNetworkSecurityGroup | Where-Object {$_.Name.Contains("PRD")}| Select-Object Name | AddOrUpdateRDPRecord | Out-Null
Write-Output("All network rules are updated")

Get-AzSqlServer | ForEach-Object{
 Set-AzSqlServerFirewallRule -ResourceGroupName $_.ResourceGroupName -ServerName $_.ServerName -FirewallRuleName "Atul" -StartIpAddress $myIp -EndIpAddress $myIp
} | Out-Null
Write-Output("All DB server firewall rules are updated")

Write-Host "Press any key to continue ....."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")