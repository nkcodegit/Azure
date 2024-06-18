## To find VM cost recommendations
```
advisorresources
    | where type == 'microsoft.advisor/recommendations'
    | where properties.category == 'Cost'
    | where properties.impactedField =~ 'Microsoft.Compute/virtualMachines'
    | project VM=properties.impactedValue, Current=properties.extendedProperties.currentSku, Target=properties.extendedProperties.targetSku, MaxCPUP95=properties.extendedProperties.MaxCpuP95, MaxMemoryP95=properties.extendedProperties.MaxMemoryP95, MaxNetworkP95=properties.extendedProperties.MaxTotalNetworkP95,subscription=subscriptionId
    | order by subscription asc
```

## Find VM by guest name
```
Resources
	| where type =~ 'Microsoft.Compute/virtualMachines'
	| where properties.osProfile.computerName =~ 'savazuusscdc01' or properties.extended.instanceView.computerName =~ 'savazuusscdc01'
	| join (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
	| project VMName = name, CompName = properties.osProfile.computerName, OSType =  properties.storageProfile.osDisk.osType, RGName = resourceGroup, SubName, SubID = subscriptionId
```

## VM by power state
```
Resources
| where type == 'microsoft.compute/virtualmachines'
| summarize count() by tostring(properties.extended.instanceView.powerState.code)
```

## Unused Managed Disks
```
Resources 
| where type =~ 'Microsoft.Compute/disks'
| where managedBy =~ '' 
| project name, resourceGroup, subscriptionId, location, tags, sku.name, id

```
## Unused Public IPs
```
Resources 
| where type =~ 'Microsoft.Network/publicIPAddresses' 
|where properties.ipConfiguration =~ '' 
|project name, resourceGroup, subscriptionId, location, tags, id
```

## VMSS Autoscale
```
Resources
    | where type =~ 'Microsoft.Compute/virtualMachineScaleSets'
    | join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
    | project VMMSName = name, RGName = resourceGroup, VMMSSKU = sku.name, VMMSCount = sku.capacity, SubName, SubID = subscriptionId, ResID = id
```

## Link to scale action
```
Resources
    | where type =~ 'Microsoft.Compute/virtualMachineScaleSets'
    | extend lowerId = tolower(id)
    | join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
    | join kind=leftouter (Resources | where type=='microsoft.insights/autoscalesettings' | project ScaleName=tostring(properties.name),lowerId=tolower(tostring(properties.targetResourceUri))) on lowerId
    | project VMMSName = name, RGName = resourceGroup, VMMSSKU = sku.name, VMMSCount = sku.capacity, SubName, SubID = subscriptionId, ResID = id, ScaleName
```

## Just scale actions
```
Resources
    | where type=='microsoft.insights/autoscalesettings'
    | where properties.targetResourceUri contains 'virtualmachinescalesets'
```

## With some information about the scale
```
Resources
    | where type =~ 'Microsoft.Compute/virtualMachineScaleSets'
    | extend lowerId = tolower(id)
    | join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
    | join kind=leftouter (Resources | where type=='microsoft.insights/autoscalesettings' | project ScaleName=tostring(properties.name), minCount=properties.profiles[0].capacity.minimum, maxCount=properties.profiles[0].capacity.maximum,lowerId=tolower(tostring(properties.targetResourceUri))) on lowerId
    | project VMMSName = name, RGName = resourceGroup, VMMSSKU = sku.name, VMMSCount = sku.capacity, SubName, SubID = subscriptionId, ResID = id, ScaleName, minCount, maxCount
```

## Find all Azure Firewall instances in a sub that has AKS as well
```
Resources
| where type =~ 'microsoft.network/azurefirewalls'
| project fwname = name, subscriptionId
| join kind=inner (
    Resources
    | where type =~ 'microsoft.containerservice/managedclusters'
    | project aksname = name, subscriptionId)
on subscriptionId
| distinct subscriptionId, fwname
| join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
| project-away subscriptionId1
```

## Find all CosmosDB accounts without Private Endpoints
```
resources
| where type == "microsoft.documentdb/databaseaccounts"
| where isnull(properties['privateEndpointConnections'])
| project dbname = name, rgname = resourceGroup, subscriptionId
| join kind=leftouter (
    resourcecontainers
    | where type=='microsoft.resources/subscriptions'
    | project SubName=name, subscriptionId)
on subscriptionId
| project-away subscriptionId1
```

## Find all Linux VMs with OMS Agent not set to auto update
```
Resources
	| where type =~ 'Microsoft.Compute/virtualMachines'
	| where properties.storageProfile.osDisk.osType =~ 'Linux'
    | extend
        JoinID = toupper(id),
        OSName = tostring(properties.osProfile.computerName),
        OSType = tostring(properties.storageProfile.osDisk.osType),
        VMSize = tostring(properties.hardwareProfile.vmSize)
    | join kind=inner(
        Resources
        | where type == 'microsoft.compute/virtualmachines/extensions'
        | where name =~ 'OmsAgentForLinux' and properties.autoUpgradeMinorVersion =~ 'false'
        | extend
            VMId = toupper(substring(id, 0, indexof(id, '/extensions'))),
            ExtensionName = name
    ) on $left.JoinID == $right.VMId
	| join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
	| project VMName = name, CompName = properties.osProfile.computerName, OSType =  properties.storageProfile.osDisk.osType, RGName = resourceGroup, SubName, SubID = subscriptionId
```

## SQL DB and its Server FQDN (have to match based on part of the resource ID of the DB)
## Note the split has [" "] around so have to remove first 2 and last 2 characters
```
resources
| where type == "microsoft.sql/servers/databases"
| where sku.name != "System"
| extend dbserver = substring(tostring(split(id, '/databases', 0)),2,(strlen(split(id, '/databases', 0))-4))
| project dbserver, name
| join kind=leftouter (
    resources
    | where type == "microsoft.sql/servers"
    | where sku.name != "System"
    | extend FQDN = tostring(properties.fullyQualifiedDomainName)
    | project dbserver = id, FQDN)
    on dbserver
| project-away dbserver1
```

## Find any duplicate PEs within a Vnet
```
Resources
| where type == "microsoft.network/networkinterfaces"
| where isnotnull(properties['privateEndpoint'])
| extend subnet = properties['ipConfigurations'][0]['properties']['subnet']['id']
| extend PEVnet = (substring(subnet,0,indexof(subnet,'/subnets')))
| project id, name, provState = properties.provisioningState,
    PLSService = tostring(properties['ipConfigurations'][0]['properties']['privateLinkConnectionProperties']['fqdns'][0]),
    PEVnet
| summarize PECount = count() by PEVnet, PLSService
| where PECount > 1
```

## Just list them all
```
Resources
| where type == "microsoft.network/networkinterfaces"
| where isnotnull(properties['privateEndpoint'])
| extend subnet = properties['ipConfigurations'][0]['properties']['subnet']['id']
| extend PEVnet = (substring(subnet,0,indexof(subnet,'/subnets')))
| project id, name, provState = properties.provisioningState,
    PLSService = tostring(properties['ipConfigurations'][0]['properties']['privateLinkConnectionProperties']['fqdns'][0]),
    PEVnet
```

## View Service Health Alerts
```
servicehealthresources
| where type =~ 'Microsoft.ResourceHealth/events'
| extend eventType = tostring(properties.EventType), status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = todatetime(tolong(properties.ImpactMitigationTime))
| where properties.Status == 'Active' and impactStartTime > ago(40d)
```