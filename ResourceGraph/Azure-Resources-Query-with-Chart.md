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
