#Requires -Modules AzureADPreview
<#
  All basic report of enterprise apps
#>
Param($report="$env:userprofile\Documents\AzureAD_All_Enterprise_Applications.csv")

#check to see if already logged into AAD prompt if not
if(!((Get-AzureADTenantDetail).objectid)){connect-azuread}


Get-AzureADServicePrincipal -Filter "serviceprincipaltype eq 'Application'" -all $true | `
  where tags -like "*WindowsAzureActiveDirectoryIntegratedApp*" | select PublisherName, AppDisplayName, Displayname, objectid, Appid, AccountEnabled, `
    AppRoleAssignmentRequired, Homepage, @{N="tags";E={$_.tags -join(" / ")}}  | export-csv $report -NoTypeInformation

write-host "Export is found here: $report"
