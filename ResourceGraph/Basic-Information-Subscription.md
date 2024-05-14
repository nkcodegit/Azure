## Usage
Login using "Login-AzAccount" and simply copy/paste the query. 

If you prefer to query a single subscription, al you need to do so add the "-subscription" parameter to the Search-AzGraph command
like Search-AzGraph -subscription "<SUBSCRIPTIONID>" -Query "distinct(tenantId), subscriptionId"

## Basic-Information
Get delegated Tenants + Subscriptions
```
Search-AzGraph -Query "distinct(tenantId), subscriptionId"
```

Top 10 resource by type

```
Search-AzGraph -Query "summarize count() by type 
| project type, total=count_ 
| top 10  by type 
| order by total desc"
```

Resources by location
```
Search-AzGraph -Query "summarize count() by location 
| project location, total=count_ 
| order by total desc"
```
