#export all groups app role assignments
get-azureadgroup -Filter "SecurityEnabled eq true" -All $true -pv aadgrp | Get-AzureADGroupAppRoleAssignment -all $true -pv aadgara | `
    select @{N="Group_objectID";E={$aadgrp.objectid}}, @{N="Group_Displayname";E={$aadgrp.displayname}}, `
    @{N="ServicePrincipal_objectID";E={$aadgara.ResourceId}}, @{N="ServicePrincipal_Displayname";E={$aadgara.ResourceDisplayName}} | `
        export-csv ".\Azure_AD_Security_GroupAppRoleAssignment_$((Get-AzureADTenantDetail).DisplayName)_$(get-date -f yyyy-MM-dd).csv" -NoTypeInformation
