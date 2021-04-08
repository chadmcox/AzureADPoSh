
#export all conditional access group assignments
Get-AzureADMSConditionalAccessPolicy -pv cap | select -ExpandProperty Conditions | select -ExpandProperty Users | foreach{
    $_ | select -ExpandProperty IncludeGroups | `
    select @{N="Group_objectID";E={$_}}, @{N="Group_Displayname";E={(Get-AzureADObjectByObjectId -objectids $_).displayname}}, `
    @{N="CAP_objectID";E={$cap.id}}, @{N="CAP_Displayname";E={$cap.DisplayName}},@{N="CAP_State";E={$cap.State}}, @{N="CAP_Condition";E={"IncludeGroups"}} 
    $_ | select -ExpandProperty ExcludeGroups | `
    select @{N="Group_objectID";E={$_}}, @{N="Group_Displayname";E={(Get-AzureADObjectByObjectId -objectids $_).displayname}}, `
    @{N="CAP_objectID";E={$cap.id}}, @{N="CAP_Displayname";E={$cap.DisplayName}},@{N="CAP_State";E={$cap.State}}, @{N="CAP_Condition";E={"ExcludeGroups"}}
} | export-csv ".\Azure_AD_Conditional_Access_Policy_Group_Assignment_$((Get-AzureADTenantDetail).DisplayName)_$(get-date -f yyyy-MM-dd).csv" -NoTypeInformation
