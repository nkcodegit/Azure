az login

az account list --output table

az account set --subscription "<subscription name>"

az network dns zone export -g "<Resource Grop Name>" -n "<name of the zone>" -f "<Path to the DNS zone file to save>" | Out-File -FilePath C:\AzureInventory\dns.txt
