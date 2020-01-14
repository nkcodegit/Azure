# Connect to Azure
Connect-AzAccount

# Once signed in, use the Azure PowerShell cmdlets to access and manage resources in your subscription. 
Get-AzSubscription

# Select a subscription by name
Set-AzContext -Subscription '<SubscriptionName>'

$result = "C:\Temp\azureresult.csv" 

"SubscriptionName,SubscriptionId,Resource,Name,ResourceGroupName,ResourceId" `
		| out-file $result -encoding ascii

# Loop through the resources and add to the output file
ForEach ($resource in Get-AzResource) 
{
	$AzureSubscription.Name + "," + `
		$AzureSubscription.SubscriptionId + "," + `
		$resource.ResourceType + "," + `
		$resource.Name + "," + `
		$resource.ResourceGroupName + "," + `
		$resource.ResourceId `
		| out-file $result -encoding ascii -append
}

Write-Output "Check $result"
