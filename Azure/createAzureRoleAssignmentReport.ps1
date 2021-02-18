#
.VERSION 2021.2.18
.GUID 809ca830-a28a-45ea-888f-aa200e857d98
.AUTHOR Chad.Cox@microsoft.com
    https://blogs.technet.microsoft.com/chadcox/ (retired)
    https://github.com/chadmcox
.COMPANYNAME 
.COPYRIGHT This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys` fees, that arise or result
from the use or distribution of the Sample Code..
.DESCRIPTION
#> 

connect-azuread
connect-azaccount

$hash_sublookup = Get-AzSubscription | select name, id | group id -AsHashTable -AsString
$hash_alreadyresolved = @{}
function findScopeCaseforPIM{
    [cmdletbinding()]
    param($scope)
    if($hash_alreadyresolved.ContainsKey($scope)){
        return $hash_alreadyresolved[$scope]
    }
    if(($scope -split "/")[-2] -eq "managementGroups"){
        return (Get-AzManagementGroup -GroupName ($Scope -split "/")[-1]).id
    }elseif(($scope -split "/")[-2] -eq "subscriptions"){
        return "/subscriptions/$((Get-AzSubscription -SubscriptionId ($Scope -split "/")[-1]).id)"
    }elseif(($scope -split "/")[-2] -eq "resourceGroups"){
        return (Get-AzResourceGroup -id $scope).ResourceId
    }elseif($scope -eq "/"){
        return $scope
    }else{
        return (Get-AzResource -ResourceId $scope).ResourceId
    }
}
function gatherAzureRoleMembers{
    [cmdletbinding()]
    param()
    Get-AzSubscription -pv sub | set-azcontext | foreach{
        write-host "Enumerating: $($sub.name)"
        Get-AzRoleAssignment -IncludeClassicAdministrators -pv assignment | foreach{
            foreach($rn in ($assignment.RoleDefinitionName -split ";")){
                #I have found that scope returns random case sometimes which doesnt work for PIM
                #I perform a lookup 
                $rolescope = ""; $rolescope = findScopeCaseforPIM -scope $assignment.Scope
                if(!($hash_alreadyresolved.ContainsKey($assignment.Scope))){$hash_alreadyresolved.add($assignment.Scope,$rolescope)}
                if($assignment.ObjectType -eq "Group"){#enumerate members of group, this is not recursive
                    Get-AzADGroupMember -GroupObjectId $assignment.objectid -pv gm | select `
                        @{Name="Scope";Expression={$rolescope}}, `
                    @{Name="ScopeType";Expression={($assignment.Scope -split "/")[-2]}}, `
                    @{Name="RoleDefinitionName";Expression={$rn}}, `
                    @{Name="RoleDefinitionId";Expression={$assignment.RoleDefinitionId}}, `
                    @{Name="DisplayName";Expression={$gm.DisplayName}}, `
                    @{Name="SignInName";Expression={$gm.UserPrincipalName}}, `
                    @{Name="ObjectID";Expression={$gm.ID}}, `
                    @{Name="ObjectType";Expression={"MemberOf - $($assignment.DisplayName)"}}, `
                    @{Name="Subscription";Expression={if(!(($assignment.Scope -split "/")[-2] -eq "")){`
                        "$($hash_sublookup[($assignment.Scope -split "/")[2]].name) ($($hash_sublookup[($assignment.Scope -split "/")[2]].id))"}}}, `
                    AssignmentState
            
                }#enumerate all the accounts
                $_ | select @{Name="Scope";Expression={$rolescope}}, `
                    @{Name="ScopeType";Expression={($assignment.Scope -split "/")[-2]}}, `
                    @{Name="RoleDefinitionName";Expression={$rn}}, `
                    @{Name="RoleDefinitionId";Expression={$assignment.RoleDefinitionId}}, `
                    @{Name="DisplayName";Expression={$assignment.DisplayName}}, `
                    @{Name="SignInName";Expression={$assignment.SignInName}}, `
                    @{Name="ObjectID";Expression={$assignment.ObjectID}}, `
                    @{Name="ObjectType";Expression={$assignment.Objecttype}}, `
                    @{Name="Subscription";Expression={if(!(($assignment.Scope -split "/")[-2] -eq "managementGroups")){`
                        "$($hash_sublookup[($assignment.Scope -split "/")[2]].name) ($($hash_sublookup[($assignment.Scope -split "/")[2]].id))"}}}, `
                    AssignmentState
            }
        } 
    } 
}

function gatherPIMRoleMembers{
    $uniqueScopes = import-csv .\azureRoleMembers.csv | select scope -Unique
    foreach($sc in $uniqueScopes.scope){
        write-host "Enumerating: PIM $sc"
        Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$sc'" -pv resource | foreach {
            Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $resource.id -pv pimrole | foreach{
                write-host "Enumerating: PIM $($pimrole.DisplayName)"
                Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $resource.id -filter "RoledefinitionId eq '$($pimrole.id)'" `
                    -pv assignment | where {$_.membertype -ne "Inherited"} | foreach{
                    Get-AzureADObjectByObjectId -ObjectIds $assignment.SubjectId -pv account | where {$_.displayname -ne "MS-PIM"} | foreach{
                        if($account.objecttype -eq "Group"){
                            Get-AzADGroupMember -GroupObjectId $account.objectid -pv gm | select `
                                @{Name="Scope";Expression={$sc}}, `
                                @{Name="ScopeType";Expression={($sc -split "/")[-2]}}, `
                                @{Name="RoleDefinitionName";Expression={$pimrole.DisplayName}}, `
                                @{Name="RoleDefinitionId";Expression={($pimrole.ExternalId -split "/")[-1]}}, `
                                @{Name="DisplayName";Expression={$gm.DisplayName}}, `
                                @{Name="SignInName";Expression={$gm.UserPrincipalName}}, `
                                @{Name="ObjectID";Expression={$gm.ID}}, `
                                @{Name="ObjectType";Expression={"MemberOf - $($account.DisplayName)"}}, `
                                @{Name="Subscription";Expression={if(!(($sc -split "/")[-2] -eq "managementGroups")){`
                                    "$($hash_sublookup[($sc -split "/")[2]].name) ($($hash_sublookup[($sc -split "/")[2]].id))"}}}, `
                                @{Name="AssignmentState";Expression={$assignment.AssignmentState}}
                        } 
                        $account | select `
                            @{Name="Scope";Expression={$sc}}, `
                            @{Name="ScopeType";Expression={($sc -split "/")[-2]}}, `
                            @{Name="RoleDefinitionName";Expression={$pimrole.DisplayName}}, `
                            @{Name="RoleDefinitionId";Expression={($pimrole.ExternalId -split "/")[-1]}}, `
                            @{Name="DisplayName";Expression={$account.DisplayName}}, `
                            @{Name="SignInName";Expression={$account.UserPrincipalName}}, `
                            @{Name="ObjectID";Expression={$account.objectID}}, `
                            @{Name="ObjectType";Expression={$account.objecttype}}, `
                            @{Name="Subscription";Expression={if(!(($sc -split "/")[-2] -eq "managementGroups")){`
                                "$($hash_sublookup[($sc -split "/")[2]].name) ($($hash_sublookup[($sc -split "/")[2]].id))"}}}, `
                            @{Name="AssignmentState";Expression={$assignment.AssignmentState}}
                    }
                }
            }
        }
    }
}
write-host "Getting all Azure Roles"
gatherAzureRoleMembers | export-csv .\azureRoleMembers.csv -notypeinformation
write-host "Getting all Azure Roles in PIM"
gatherPIMRoleMembers | export-csv .\azureRoleMembers.csv -Append -NoTypeInformation



