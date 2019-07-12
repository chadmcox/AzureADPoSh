Get-AzureADAuditDirectoryLogs -Filter "activityDisplayName eq 'Consent to application'" `
-all $true | select -expandproperty TargetResources | select ID, Displayname | `
 group displayname | select name, count
