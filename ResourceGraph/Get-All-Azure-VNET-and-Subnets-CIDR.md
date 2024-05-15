## Get All Azure VNET and Subnets CIDR Detail
```
Resources 
| where type =~ "microsoft.network/virtualnetworks" 
| extend subnet = properties.subnets 
| mv-expand subnet
| project VNetName=name, VNetCIDR=properties.addressSpace.addressPrefixes, subnetName=subnet.name, subnetCIDR=subnet.properties.addressPrefix
// | where subnetName =~ "gatewaysubnet" // Add this where filter if required to find a specific subnet name across all the VNets
```
