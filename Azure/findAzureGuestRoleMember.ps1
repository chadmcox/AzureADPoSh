$hash_sublookup = Get-AzSubscription | select name, id | group id -AsHashTable -AsString

Get-AzSubscription | set-azcontext | foreach{
    Get-AzRoleAssignment -IncludeClassicAdministrators -pv assignment | foreach{
        foreach($rn in ($assignment.RoleDefinitionName -split ";")){
            if($assignment.ObjectType -eq "Group"){#enumerate members of group, this is not recursive
                Get-AzADGroupMember -GroupObjectId $assignment.objectid -pv gm | select `
                    @{Name="Scope";Expression={$assignment.Scope}}, `
                @{Name="ScopeType";Expression={($assignment.Scope -split "/")[-2]}}, `
                @{Name="RoleDefinitionName";Expression={$rn}}, `
                @{Name="RoleDefinitionId";Expression={$assignment.RoleDefinitionId}}, `
                @{Name="DisplayName";Expression={$gm.DisplayName}}, `
                @{Name="SignInName";Expression={$gm.UserPrincipalName}}, `
                @{Name="ObjectID";Expression={$gm.ID}}, `
                @{Name="ObjectType";Expression={"MemberOf - $($assignment.DisplayName)"}}, `
                @{Name="Subscription";Expression={if(!(($assignment.Scope -split "/")[-2] -eq "")){`
                    "$($hash_sublookup[($assignment.Scope -split "/")[2]].name) ($($hash_sublookup[($assignment.Scope -split "/")[2]].id))"}}}
            
            }#enumerate all the accounts
            $_ | select @{Name="Scope";Expression={$assignment.Scope}}, `
                @{Name="ScopeType";Expression={($assignment.Scope -split "/")[-2]}}, `
                @{Name="RoleDefinitionName";Expression={$rn}}, `
                @{Name="RoleDefinitionId";Expression={$assignment.RoleDefinitionId}}, `
                @{Name="DisplayName";Expression={$assignment.DisplayName}}, `
                @{Name="SignInName";Expression={$assignment.SignInName}}, `
                @{Name="ObjectID";Expression={$assignment.ObjectID}}, `
                @{Name="ObjectType";Expression={$assignment.Objecttype}}, `
                @{Name="Subscription";Expression={if(!(($assignment.Scope -split "/")[-2] -eq "managementGroups")){`
                    "$($hash_sublookup[($assignment.Scope -split "/")[2]].name) ($($hash_sublookup[($assignment.Scope -split "/")[2]].id))"}}}
        }
    } | where {$_.SignInName -like "*#EXT#*"}
} | export-csv .\azureGuestRoleMembers.csv -notypeinformation
