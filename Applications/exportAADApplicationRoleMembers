#Requires -Modules AzureADPreview
<#
  this will list all the applications a user has been assigned to
#>
Param($user=$(read-host "Enter Users email"))

#check to see if already logged into AAD prompt if not
if(!((Get-AzureADTenantDetail).objectid)){connect-azuread}

get-azureaduser -ObjectId $user | Get-AzureADUserAppRoleAssignment | select PrincipalDisplayName, ResourceDisplayName
