#Requires -Modules AzureADPreview
<#
  All basic report of enterprise apps
#>
Param($report="$env:userprofile\Documents\AzureAD_All_Enterprise_Applications.csv")

#only prompt for connection if needed
try{Get-AzureADCurrentSessionInfo}
catch{Connect-azuread}


Get-AzureADServicePrincipal -Filter "serviceprincipaltype eq 'Application'" -all $true | `
  where tags -like "*WindowsAzureActiveDirectoryIntegratedApp*" | select PublisherName, AppDisplayName, Displayname, objectid, Appid, AccountEnabled, `
    AppRoleAssignmentRequired, Homepage, @{N="tags";E={$_.tags -join(" / ")}}  | export-csv $report -NoTypeInformation

write-host "Export is found here: $report"
