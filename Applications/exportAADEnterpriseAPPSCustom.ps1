#Requires -Modules AzureADPreview
<#
  basic report of enterprise apps added into the tenant
#>
Param($report="$env:userprofile\Documents\AzureAD_Enterprise_Applications.csv")

#only prompt for connection if needed
try{Get-AzureADCurrentSessionInfo}
catch{Connect-azuread}

$company = (Get-AzureADTenantDetail).displayname

Get-AzureADServicePrincipal -Filter "serviceprincipaltype eq 'Application' and publishername eq '$company'" -all $true | `
  where tags -like "*WindowsAzureActiveDirectoryIntegratedApp*" | select PublisherName, AppDisplayName, Displayname, objectid, Appid, AccountEnabled, `
    AppRoleAssignmentRequired, Homepage, @{N="tags";E={$_.tags -join(" / ")}}  | export-csv $report -NoTypeInformation

write-host "Export is found here: $report"
