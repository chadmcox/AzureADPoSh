Get-AzSubscription -pv sub | set-azcontext | foreach{
    write-host "Enumerating: $($sub.name)"
    Get-AzRoleAssignment -IncludeClassicAdministrators -pv assignment | foreach{
        foreach($rn in ($assignment.RoleDefinitionName -split ";")){
            $_ | select @{Name="Scope";Expression={$assignment.Scope}}, `
                @{Name="ScopeType";Expression={($assignment.Scope -split "/")[-2]}}, `
                @{Name="RoleDefinitionName";Expression={$rn}}, `
                @{Name="RoleDefinitionId";Expression={$assignment.RoleDefinitionId}}, `
                @{Name="DisplayName";Expression={$assignment.DisplayName}}, `
                @{Name="SignInName";Expression={$assignment.SignInName}}, `
                @{Name="ObjectID";Expression={$assignment.ObjectID}}, `
                @{Name="ObjectType";Expression={$assignment.Objecttype}}, `
                @{Name="Subscription";Expression={"$($sub.name) - ($sub.id)"}}
        }
    } 
} | export-csv ".\Azure_Role_Assignment_$((Get-AzureADTenantDetail).DisplayName)_$(get-date -f yyyy-MM-dd).csv" -NoTypeInformation
