#Requires -modules Az.Accounts,Az.Resources,azureadpreview
#Requires -version 4.0
<#PSScriptInfo
.VERSION 2020.7.2.1
.GUID 476739f9-d907-4d5a-856e-71f9279955de
.AUTHOR Chad.Cox@microsoft.com
    https://blogs.technet.microsoft.com/chadcox/
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
 retrieves all objects and  
#> 
param($reportpath="$env:userprofile\Documents")
$export_report = "$reportpath\Azure_Resources_RBAC_All_Export_$(get-date -f yyyy-MM-dd-HH-mm).csv"
$pim_report = "$reportpath\Azure_Resources_RBAC_PIM_Enabled_Export_$(get-date -f yyyy-MM-dd-HH-mm).csv"
$notpim_report = "$reportpath\Azure_Resources_RBAC_PIM_Not_Enabled_Export_$(get-date -f yyyy-MM-dd-HH-mm).csv"

function Retrieve-AllAZResources{
    Get-AzManagementGroup | select * | select @{Name="SubscriptionID";Expression={$_.TenantId}}, `
            @{Name="SubscriptionName";Expression={"Management Group"}}, `
            @{Name="SubscriptionState";Expression={"Enabled"}}, `
            @{Name="ResourceID";Expression={$_.id}}, `
            @{Name="ResourceName";Expression={$_.name}}, `
            @{Name="ResourceType";Expression={$_.type}}
    Get-AzSubscription -pv azs | where state -eq "Enabled" | Set-AzContext | foreach{
        $azs | select @{Name="SubscriptionID";Expression={$azs.id}}, `
            @{Name="SubscriptionName";Expression={$azs.name}}, `
            @{Name="SubscriptionState";Expression={$azs.state}}, `
            @{Name="ResourceID";Expression={"/subscriptions/$($azs.id)"}}, `
            @{Name="ResourceName";Expression={$azs.Name}}, `
            @{Name="ResourceType";Expression={"Subscriptions"}}
        get-azresource -pv azr | select @{Name="SubscriptionID";Expression={$azs.id}}, `
            @{Name="SubscriptionName";Expression={$azs.name}}, `
            @{Name="SubscriptionState";Expression={$azs.state}}, `
            @{Name="ResourceID";Expression={$azr.ResourceId}}, `
            @{Name="ResourceName";Expression={$azr.Name}}, `
            @{Name="ResourceType";Expression={$azr.ResourceType}}
    }
}

function Create-AZRBACResults{
    $progresstotal = $azureResources.count; write-host "First Exporting Resource RBAC Members only $progresstotal to enumerate!!"
    $i = 0
    foreach($azr in $azureResources){
        $dont = Set-AzContext -Subscription $azr.SubscriptionID
        Get-AzRoleAssignment -pv azra | select `
            @{Name="ResourceID";Expression={$azra.Scope}}, `
            @{Name="RoleAssignmentId";Expression={$azra.RoleAssignmentId}}, `
            @{Name="RoleDefinitionName";Expression={$azra.RoleDefinitionName}}, `
            @{Name="MemberObjectID";Expression={$azra.objectid}}, `
            @{Name="MemberDisplayname";Expression={$azra.DisplayName}}, `
            @{Name="MemberSigninName";Expression={$azra.SignInName}}, `
            @{Name="MemberObjectType";Expression={$azra.ObjectType}}
    }
}
function find-AZResourcesNotPIMEnabled{
    write-host "searching for non pim enabled resources"
    $azureResourceslist = import-csv $export_report | group resourceid
    $progresstotal = $azureResourceslist.count; write-host "Second Looking through $progresstotal resources to see if they are not enabled!!"
    $azureResourceslist | where {!(Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$(($_).name)'")} | select -ExpandProperty group
}
function find-AZResourcesPIMEnabled{
    $pimResources = import-csv $export_report | where MemberDisplayname -eq "MS-PIM" | select ResourceID,SubscriptionID,SubscriptionName
    $progresstotal = $pimResources.count; write-host "Last Exporting PIM Managed RBAC Members, only $progresstotal to enumerate!!"
    foreach($azr in $pimResources){
        Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$(($azr).ResourceID)'" -pv pim | foreach{
            Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $pim.ID -pv azpra | where MemberType -eq "Direct" | foreach{
                $role = Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -id $azpra.RoleDefinitionId -ResourceId $azpra.ResourceId
                Get-AzureADObjectByObjectId -ObjectId $azpra.SubjectId -pv member | select `
                    @{Name="SubscriptionID";Expression={$azr.SubscriptionID}}, `
                    @{Name="SubscriptionName";Expression={$azr.SubscriptionName}}, `
                    @{Name="ResourceID";Expression={$azr.ResourceID}}, `
                    @{Name="PIMResourceID";Expression={$pim.ID}}, `
                    @{Name="PIMRoleStatus";Expression={$pim.status}}, `
                    @{Name="PIMRoleRegisteredDateTime";Expression={$pim.RegisteredDateTime}}, `
                    @{Name="PIMRegisteredRoot";Expression={$pim.RegisteredRoot}}, `
                    @{Name="RoleAssignmentId";Expression={$azpra.externalid}}, `
                    @{Name="RoleDefinitionName";Expression={$role.DisplayName}}, `
                    @{Name="MemberObjectID";Expression={$azpra.SubjectId}}, `
                    @{Name="MemberDisplayname";Expression={$member.DisplayName}}, `
                    @{Name="MemberSigninName";Expression={$member.userprincipalname}}, `
                    @{Name="MemberObjectType";Expression={$member.ObjectType}}, `
                    @{Name="PIMMemberStartDateTime";Expression={$azpra.StartDateTime}}, `
                    @{Name="PIMMemberAssignmentState";Expression={$azpra.AssignmentState}}, `
                    @{Name="PIMMemberType";Expression={$azpra.MemberType}}
                }}}      
}
cls
$resource_export_file = "$env:userprofile\Documents\resource.tmp"
Get-ChildItem $resource_export_file | where {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Force
if(!(test-path $resource_export_file)){
    write-host "cache resources not found, recreating"
    Retrieve-AllAZResources | export-csv $resource_export_file -NoTypeInformation
}else{
    write-host "cache resources found"
}
$azureResources = import-csv $resource_export_file | where ResourceType -eq "Subscriptions"
$hash_lookup_table = import-csv $resource_export_file | group resourceid -AsHashTable -AsString
write-host "Creating Report extracting all RBAC Role Members"

$time_to_complete = measure-command {
Create-AZRBACResults | select * -Unique | select `
    @{Name="SubscriptionID";Expression={$hash_lookup_table["$($_.ResourceID)"].SubscriptionID}}, `
    @{Name="SubscriptionName";Expression={$hash_lookup_table["$($_.ResourceID)"].SubscriptionName}}, `
    ResourceID,RoleAssignmentId,RoleDefinitionName, MemberObjectID,MemberDisplayname,MemberSigninName,MemberObjectType | `
        export-csv $export_report -NoTypeInformation
     
}
write-host "Complete in $($time_to_complete.Minutes) Min / $($time_to_complete.Seconds) sec"
write-host "Complete Export found here $export_report" -ForegroundColor Yellow
write-host "Creating Report for Resources pim not enabled" 
$time_to_complete = measure-command {find-AZResourcesNotPIMEnabled | export-csv $notpim_report -NoTypeInformation}
write-host "Complete in $($time_to_complete.Minutes) Min / $($time_to_complete.Seconds) sec"
write-host "Complete Export found here $notpim_report" -ForegroundColor Yellow
write-host "Creating Report for Resources pim not enabled" 
$time_to_complete = measure-command {find-AZResourcesPIMEnabled | export-csv $pim_report -NoTypeInformation}
write-host "Complete in $($time_to_complete.Minutes) Min / $($time_to_complete.Seconds) sec"
write-host "Complete Export found here $pim_report" -ForegroundColor Yellow
write-host "Finished"
