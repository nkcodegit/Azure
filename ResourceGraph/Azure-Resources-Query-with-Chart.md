Azure Resource Graph (ARG) query to fetch all resources with detailed information, including their subscription, resource group, location, type, SKU, tags, and provisioning state. Additionally, this query groups resources by type to generate a chart in Azure Resource Graph Explorer.

```
Resources
| extend sku = tostring(properties.sku.name) 
| extend provisioningState = tostring(properties.provisioningState)
| project 
    id, 
    name, 
    type, 
    subscriptionId, 
    resourceGroup, 
    location, 
    sku, 
    provisioningState, 
    tags
| summarize count() by type
| order by count_ desc
```
