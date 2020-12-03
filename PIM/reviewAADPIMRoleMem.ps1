Param($report="$env:userprofile\Documents\AADPIMRoleMembers.csv")

#get all privilaged role membersrole members
Get-AzureADMSPrivilegedRoleDefinition -ProviderId "aadRoles" -ResourceId (Get-AzureADTenantDetail).objectid -pv role | foreach{
  write-host "Expanding $($role.displayname)"
    Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId (Get-AzureADTenantDetail).objectid `
        -filter "RoleDefinitionId eq '$($role.id)'" -pv mem | foreach{
            Get-AzureADObjectByObjectId -ObjectIds $mem.subjectid | select @{N="Role";E={$role.displayname}}, `
                @{N="Member";E={$_.displayname}}, userprincipalname, objecttype, @{N="AssignmentState";E={$mem.AssignmentState}}, `
                @{N="MemberType";E={$mem.MemberType}}, @{N="EndDateTime";E={$mem.EndDateTime}}
        }
} | export-csv $report -notypeinformation
