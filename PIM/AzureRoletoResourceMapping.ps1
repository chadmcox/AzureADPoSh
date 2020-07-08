#Requires -modules azureadpreview,Az.Resources,Az.Accounts

param($scriptpath="$env:USERPROFILE\Documents\AzureAccessReport")
if(!(test-path $scriptpath)){
    new-item -Path $scriptpath -ItemType Directory
}

cd $scriptpath

if(!(Get-AzureADCurrentSessionInfo)){
    write-host "Logon to Azure AD"
    Connect-AzureAD
}
if(!(Get-AzSubscription)){
    write-host "logon to Azure"
    Connect-AzAccount
}

#region Supporting Functions
function enumerate-aadgroup{
    param($objectid)
    get-azureadgroupmember -ObjectId $objectid -pv mem | foreach{
        $_ | select @{Name="ObjectID";Expression={$mem.objectId}}, `
            @{Name="ObjectType";Expression={"GroupMember - $($mem.ObjectType)"}}, `
            @{Name="Displayname";Expression={$mem.DisplayName}}, `
            @{Name="SigninName";Expression={$mem.userprincipalname}}
        if($_.group){
            enumerate-aadgroup -ObjectId $_.objectid
        }
    }
}
function check-file{
    param($file)
    if(!(Test-Path $file)){
        write-host "$file not found"
        return $true      
    }elseif(!((Get-Item $file).length/1KB -gt 1/1kb)){
        write-host "$file is empty"
        return $true
    }elseif((get-item -Path .\grpm.tmp).LastWriteTime -lt (get-date).AddDays(-3)){
        write-host "$file is older than 3 days"
        return $true
    }else{
        write-host "$file seems reusable"
        return $false
    }
}
function expand-azuremg{
    param($mg)
    if($mg){
        $hash_mg[$mg] | foreach{
            $_ | select @{Name="ID";Expression={$amg.id}}, `
            @{Name="name";Expression={$amg.displayname}}, `
            @{Name="type";Expression={$amg.type}}, `
            @{Name="ChildID";Expression={$_.Child}}, `
            @{Name="ChildType";Expression={$_.childtype}}, `
            @{Name="Childname";Expression={$_.childname}}
            expand-azuremg -mg $_.child
        }
    }
}
#endregion
#region Management Groups Exports
$mg_File = ".\mg.tmp"
if(check-file -file $mg_file){
    write-host "Exporting Azure Management Group Relationships"
    $hash_mg = Get-AzManagementGroup | foreach{
        Get-AzManagementGroup -GroupName $_.name -Expand -pv parent
    } | select -ExpandProperty Children | select @{Name="Parent";Expression={$parent.ID}}, @{Name="Child";Expression={$_.id}}, `
        @{Name="childname";Expression={$_.displayname}},@{Name="ChildType";Expression={$_.type}} | group parent -AsHashTable -AsString

    Get-AzManagementGroup -pv amg | foreach{
        expand-azuremg -mg $amg.id 
    } | export-csv $mg_File -NoTypeInformation
}
$resm_File_updated = $null
$resm_File = ".\res_map.tmp"
if(check-file -file $resm_File){
    $resm_File_updated = $true
    write-host "Exporting Azure Management Groups for RBAC"
    get-azManagementGroup | select @{Name="ManagementGroupID";Expression={$_.ID}}, `
        @{Name="ManagementGroupName";Expression={$_.displayname}}, `
        @{Name="SubscriptionID";Expression={}}, `
        @{Name="SubscriptionName";Expression={}}, `
        @{Name="ResourceID";Expression={$_.ID}}, `
        @{Name="ResourceName";Expression={$_.displayname}}, `
        @{Name="ResourceType";Expression={$_.type}}, `
        @{Name="ResourceGroupName";Expression={}} | export-csv $resm_File
}
#endregion
#region Resource Exports
$res_file = ".\res.tmp"
if(check-file -file $res_File){
    Write-host "Exporting All Azure Subscriptions and Resources"
    get-azsubscription -pv azs | Set-AzContext | foreach{
        $azs | select @{Name="SubscriptionID";Expression={"/subscriptions/$($azs.ID)"}}, `
            @{Name="SubscriptionName";Expression={"$($azs.name)"}}, `
            @{Name="ResourceID";Expression={"/subscriptions/$($azs.ID)"}}, `
            @{Name="ResourceName";Expression={"$($azs.name)"}}, `
            @{Name="ResourceType";Expression={"/subscriptions"}}, `
            @{Name="ResourceGroupName";Expression={}}
        get-azResource -pv azr | select @{Name="SubscriptionID";Expression={"/subscriptions/$($azs.ID)"}}, `
            @{Name="SubscriptionName";Expression={"$($azs.name)"}}, `
            @{Name="ResourceID";Expression={$azr.resourceid}}, `
            @{Name="ResourceName";Expression={$azr.name}}, `
            @{Name="ResourceType";Expression={$azr.ResourceType}}, `
            @{Name="ResourceGroupName";Expression={$azr.ResourceGroupName}}
    } | export-csv $res_file -NoTypeInformation
}
#endregion
#region Role Export
$rbac_file = ".\rbac.tmp"
if(check-file -file $rbac_file){
    write-host "Exporting all Azure Role Assignment from Subscriptions"
    get-azsubscription -pv azs | Set-AzContext | foreach{
        get-azRoleAssignment -pv azr | select scope, RoleDefinitionName,RoleDefinitionId,ObjectId,ObjectType, `
            DisplayName,SignInName,AssignmentState, @{Name="AssignmentType";Expression={"azRoleAssignment"}}
    } | export-csv $rbac_file -NoTypeInformation
}

$pim_File = ".\pim.tmp"
if(check-file -file $pim_File){
    write-host "Exporting all Privileged Identity Management Enabled Azure Roles and Members"
    import-csv $rbac_file  | where Displayname -eq "MS-PIM" | group scope -pv azr  | foreach{
        Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$(($azr).name)'" -pv pim | foreach{
            Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $pim.ID -pv azpra | where MemberType -eq "Direct" | foreach{
                $role = Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -id $azpra.RoleDefinitionId -ResourceId $azpra.ResourceId
                    Get-AzureADObjectByObjectId -ObjectId $azpra.SubjectId -pv member | select `
                         @{Name="Scope";Expression={$(($azr).name)}}, `
                         @{Name="RoleDefinitionName";Expression={$role.DisplayName}}, `
                         @{Name="RoleDefinitionId";Expression={$azpra.RoleDefinitionId}}, `
                         @{Name="ObjectID";Expression={$azpra.SubjectId}}, `
                         @{Name="ObjectType";Expression={$member.ObjectType}}, `
                         @{Name="Displayname";Expression={$member.DisplayName}}, `
                         @{Name="SigninName";Expression={$member.userprincipalname}}, `
                         @{Name="AssignmentState";Expression={$azpra.AssignmentState}}, `
                         @{Name="AssignmentType";Expression={"PrivilegedRoleAssignment"}}
            }
        }
    } | export-csv $pim_File -notypeinformation
}
#endregion
#region Formatting and Creating Final Report
write-host "Creating Azure Resource Lookup Hash Table"
$hash_res = import-csv $res_file | group SubscriptionID -AsHashTable -AsString

write-host "Creating Hash Lookup Table for PIM Enabled Resources"
$hash_pimenabled = import-csv $rbac_file -pv azr | where Displayname -eq "MS-PIM" | group scope -AsHashTable -AsString

if($resm_File_updated){
    write-host "Mapping Management Groups to subscriptions"
    import-csv $mg_File -pv mg | foreach{
        $hash_res[$mg.childid] | select @{Name="ManagementGroupID";Expression={$mg.ID}},@{Name="ManagementGroupName";Expression={$mg.name}}, *
    } | export-csv $resm_File -Append
}

write-host "Flushing Azure Resource Lookup Hash Table"
$hash_res = @{}

$grpm_File = ".\grpm.tmp"
if(check-file -file $grpm_File){
    write-host "Expanding Azure AD Groups being used in Azure Roles"
    @(import-csv $rbac_file; import-csv $pim_File) | where ObjectType -eq "group" -PipelineVariable grp | foreach{
        enumerate-aadgroup -objectid $_.objectid | select @{Name="Scope";Expression={$grp.scope}}, `
            @{Name="RoleDefinitionName";Expression={$grp.RoleDefinitionName}}, `
            @{Name="RoleDefinitionId";Expression={$grp.RoleDefinitionId}}, `
            ObjectId,ObjectType,DisplayName,SignInName, `
            @{Name="AssignmentState";Expression={$grp.AssignmentState}}, `
            @{Name="AssignmentType";Expression={$grp.AssignmentType}} `
    } | export-csv $grpm_File -NoTypeInformation
}

Write-host "Creating Resource / Role Member Lookup Table"
$hash_rbac =  @(import-csv $rbac_file; import-csv $pim_File; import-csv $grpm_File) | group scope -AsHashTable -AsString

$final_File = ".\azure_rbac_dump.csv"
Write-host "Creating Final Report"
#map management groups
import-csv $resm_File -pv res | foreach{
    $hash_rbac[$res.ManagementGroupID] | select `
        @{Name="ManagementGroupID";Expression={$res.ManagementGroupID}}, `
        @{Name="ManagementGroupName";Expression={$res.ManagementGroupName}}, `
        @{Name="SubscriptionID";Expression={$res.SubscriptionID}}, `
        @{Name="SubscriptionName";Expression={$res.SubscriptionName}}, `
        @{Name="ResourceID";Expression={$res.resourceid}}, `
        @{Name="ResourceName";Expression={$res.ResourceName}}, `
        @{Name="ResourceType";Expression={$res.ResourceType}}, `
        @{Name="ResourceGroupName";Expression={$res.ResourceGroupName}}, `
        @{Name="Inherited";Expression={($res.resourceid -ne $_.scope)}}, *
    $hash_rbac[$res.SubscriptionID] | select `
        @{Name="ManagementGroupID";Expression={$res.ManagementGroupID}}, `
        @{Name="ManagementGroupName";Expression={$res.ManagementGroupName}}, `
        @{Name="SubscriptionID";Expression={$res.SubscriptionID}}, `
        @{Name="SubscriptionName";Expression={$res.SubscriptionName}}, `
        @{Name="ResourceID";Expression={$res.resourceid}}, `
        @{Name="ResourceName";Expression={$res.ResourceName}}, `
        @{Name="ResourceType";Expression={$res.ResourceType}}, `
        @{Name="ResourceGroupName";Expression={$res.ResourceGroupName}}, `
        @{Name="Inherited";Expression={($res.resourceid -ne $_.scope)}},  *
    $hash_rbac[$res.ResourceID] | select `
        @{Name="ManagementGroupID";Expression={$res.ManagementGroupID}}, `
        @{Name="ManagementGroupName";Expression={$res.ManagementGroupName}}, `
        @{Name="SubscriptionID";Expression={$res.SubscriptionID}}, `
        @{Name="SubscriptionName";Expression={$res.SubscriptionName}}, `
        @{Name="ResourceID";Expression={$res.resourceid}}, `
        @{Name="ResourceName";Expression={$res.ResourceName}}, `
        @{Name="ResourceType";Expression={$res.ResourceType}}, `
        @{Name="ResourceGroupName";Expression={$res.ResourceGroupName}}, `
        @{Name="Inherited";Expression={($res.resourceid -ne $_.scope)}}, *
} | select * -unique | select *,@{Name="PIMEnabled";Expression={($hash_pimenabled.ContainsKey($_.SubscriptionID) -or $hash_pimenabled.ContainsKey($_.ManagementGroupID) -or $hash_pimenabled.ContainsKey($_.resourceid))}} |  `
    export-csv $final_File -NoTypeInformation
write-host "Finished: Final File Found Here $final_File"
#endregion
