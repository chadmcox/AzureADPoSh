Get-AzureADMSPrivilegedResource -ProviderId AzureResources -pv ar | foreach{
    Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $ar.id -pv ard | foreach {
        Get-AzureADMSPrivilegedRoleSetting -ProviderId AzureResources -Filter "resourceid eq '$($ar.id)' and RoleDefinitionId eq '$($ard.id)'" | select -ExpandProperty UserMemberSettings | where RuleIdentifier -eq "MfaRule" | `
        select -expandproperty setting | ConvertFrom-Json | select @{Name="ResourceDisplayName";Expression={$ar.DisplayName}}, `
        @{Name="ResourceType";Expression={$ar.Type}}, `
        @{Name="ResourceID";Expression={$ar.ExternalId}}, `
        @{Name="RoleDisplayName";Expression={$ard.DisplayName}}, `
        @{Name="RoleID";Expression={$ard.ExternalId}}, mfarequired
    }
} | export-csv .\PIM_ROLE_MFA_Status.csv -notypeinformation
