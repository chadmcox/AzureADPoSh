<#
.VERSION 2021.3.8
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
param([switch]$expandgroupmember)
connect-azuread
connect-azaccount

$startTime = get-date


function findScopeCaseforPIM{
    [cmdletbinding()]
    param($scope)
    if(($scope -split "/")[-2] -eq "managementGroups"){
        try{return (Get-AzManagementGroup -GroupName ($Scope -split "/")[-1]).id}catch{return $scope}
    }elseif(($scope -split "/")[-2] -eq "subscriptions"){
        try{return "/subscriptions/$((Get-AzSubscription -SubscriptionId ($Scope -split "/")[-1]).id)"}catch{return $scope}
    }elseif(($scope -split "/")[-2] -eq "resourceGroups"){
        try{return (Get-AzResourceGroup -id $scope).ResourceId}catch{return $scope}
    }elseif($scope -eq "/"){
        return $scope
    }else{
        try{return (Get-AzResource -ResourceId $scope).ResourceId}catch{return $scope}
    }
}
function gatherAzureRoleMembers{
    [cmdletbinding()]
    param()
    $sub_count = (Get-AzSubscription).count
    $i = 0
    Get-AzSubscription -pv sub | set-azcontext | foreach{$i++
        write-host "Step 1 of 2 / Sub $i of $sub_count - Exporting Roles from: $($sub.name)"
        Get-AzRoleAssignment -IncludeClassicAdministrators -pv assignment | foreach{
            foreach($rn in ($assignment.RoleDefinitionName -split ";")){
                #if the object is a group and the switch is enabled then it will enumerate the groups
                if($assignment.ObjectType -eq "Group" -and $expandgroupmember -eq $true){#enumerate members of group, this is not recursive
                    Get-AzADGroupMember -GroupObjectId $assignment.objectid -pv gm | select `
                        @{Name="Scope";Expression={$assignment.Scope}}, `
                        @{Name="ScopeType";Expression={($assignment.Scope -split "/")[-2]}}, `
                        @{Name="RoleDefinitionName";Expression={$rn}}, `
                        @{Name="RoleDefinitionId";Expression={$assignment.RoleDefinitionId}}, `
                        @{Name="DisplayName";Expression={$gm.DisplayName}}, `
                        @{Name="SignInName";Expression={$gm.UserPrincipalName}}, `
                        @{Name="ObjectID";Expression={$gm.ID}}, `
                        @{Name="ObjectType";Expression={"MemberOf - $($assignment.DisplayName)"}}, `
                        @{Name="Subscription";Expression={"$($sub.name) ($($sub.id))"}}, `
                        AssignmentState
            
                }#enumerate all the accounts
                $_ | select @{Name="Scope";Expression={$assignment.Scope}}, `
                    @{Name="ScopeType";Expression={($assignment.Scope -split "/")[-2]}}, `
                    @{Name="RoleDefinitionName";Expression={$rn}}, `
                    @{Name="RoleDefinitionId";Expression={$assignment.RoleDefinitionId}}, `
                    @{Name="DisplayName";Expression={$assignment.DisplayName}}, `
                    @{Name="SignInName";Expression={$assignment.SignInName}}, `
                    @{Name="ObjectID";Expression={$assignment.ObjectID}}, `
                    @{Name="ObjectType";Expression={$assignment.Objecttype}}, `
                    @{Name="Subscription";Expression={"$($sub.name) ($($sub.id))"}}, `
                    AssignmentState
            }
        } 
    } 
}

function gatherPIMRoleMembers{
    $hash_scopes = import-csv .\azureRoleMembers.csv | select scope, Subscription -unique | group scope -AsHashTable -AsString
    #$uniqueScopes = import-csv .\azureRoleMembers.csv | where DisplayName -eq "MS-PIM" | select scope -Unique
    $pim_count = $hash_scopes.count
    $i=0
    foreach($sc in $hash_scopes.keys){$i++
        write-host "Step 2 of 2 / Scope $i of $pim_count - Exporting PIM Roles from: $sc)"
        $resource = $null; $resource = Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$sc'" -pv resource
            if(!($resource)){$pimsc = $null
                write-host "resolving case: $sc)"
                $pimsc = findScopeCaseforPIM -scope $sc
                $resource = Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$pimsc'" -pv resource
            }
            if($resource){
                Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $resource.id `
                        -pv assignment | where {$_.membertype -ne "Inherited"} | foreach{$pimrole = $null
                    $pimrole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $resource.id -Id $assignment.RoleDefinitionId -pv pimrole
                    write-host "Enumerating PIM: $($pimrole.DisplayName)"
                    Get-AzureADObjectByObjectId -ObjectIds $assignment.SubjectId -pv account | where {$_.displayname -ne "MS-PIM"} | foreach{
                        $hash_scopes[$sc].Subscription | foreach{$sub = $null; $sub = $_
                        if($account.objecttype -eq "Group" -and $expandgroupmember -eq $true){
                                Get-AzADGroupMember -GroupObjectId $account.objectid -pv gm | select `
                                    @{Name="Scope";Expression={$sc}}, `
                                    @{Name="ScopeType";Expression={($sc -split "/")[-2]}}, `
                                    @{Name="RoleDefinitionName";Expression={$pimrole.DisplayName}}, `
                                    @{Name="RoleDefinitionId";Expression={($pimrole.ExternalId -split "/")[-1]}}, `
                                    @{Name="DisplayName";Expression={$gm.DisplayName}}, `
                                    @{Name="SignInName";Expression={$gm.UserPrincipalName}}, `
                                    @{Name="ObjectID";Expression={$gm.ID}}, `
                                    @{Name="ObjectType";Expression={"MemberOf - $($account.DisplayName)"}}, `
                                    @{Name="Subscription";Expression={$sub}}, `
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
                                @{Name="Subscription";Expression={$sub}}, `
                                @{Name="AssignmentState";Expression={$assignment.AssignmentState}}
                        }
                    }}
            
        }
    }
}
write-host "Getting all Azure Roles"
gatherAzureRoleMembers | export-csv .\azureRoleMembers.csv -notypeinformation
write-host "Getting all Azure Roles in PIM"
gatherPIMRoleMembers | export-csv .\azureRoleMembers.csv -Append -NoTypeInformation
write-host "Completed after $("{0:N2}" -f (New-TimeSpan -start $startTime -end (get-date)).TotalHours) hours"
write-host "Results found in azureRoleMembers.csv"
