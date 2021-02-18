Get-AzSubscription | set-azcontext | foreach{
    Get-AzRoleAssignment -IncludeClassicAdministrators -pv assignment | foreach{
        $assignment.RoleDefinitionName -split ";" | foreach{
            $_ | select @{Name="Scope";Expression={$assignment.Scope}}, `
                @{Name="RoleDefinitionName";Expression={$_}}, `
                @{Name="RoleDefinitionId";Expression={$assignment.RoleDefinitionId}}, `
                @{Name="DisplayName";Expression={$assignment.DisplayName}}, `
                @{Name="SignInName";Expression={$assignment.SignInName}}, `
                @{Name="ObjectID";Expression={$assignment.ObjectID}}
        }
    } | where {$_.SignInName -like "*#EXT#*"}
} | export-csv .\azureGuestRoleMembers.csv -notypeinformation
