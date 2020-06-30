#Requires -modules Az.Accounts,Az.Resources,azureadpreview
#Requires -version 4.0
<#PSScriptInfo
.VERSION 2020.6.30
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
$report = "$reportpath\Azure_RBAC_PIM_Status_$(get-date -f yyyy-MM-dd-HH-mm).csv"

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
    $azureResources = Retrieve-AllAZResources
    $progresstotal = $azureResources.count
    $i = 0
    foreach($azr in $azureResources){
        Write-Progress -Activity "Enumerating Azure Resources" -Status "Enumerating" -PercentComplete ($I/$progresstotal*100);$i++
        $pim = $null;$pim = Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$(($azr).ResourceID)'"
        Get-AzRoleAssignment -scope $azr.ResourceID -pv azra | where {$azra.Scope -eq $azr.ResourceID} |  foreach{
            $member = $null;if($PIM){$member = Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $pim.ID -Filter "externalId eq '$(($azra).RoleAssignmentId)'"}
            $azra | select @{Name="SubscriptionID";Expression={$azr.SubscriptionID}}, `
                @{Name="SubscriptionName";Expression={$azr.SubscriptionName}}, `
                @{Name="SubscriptionState";Expression={$azr.SubscriptionState}}, `
                @{Name="ResourceID";Expression={$azr.ResourceID}}, `
                @{Name="ResourceName";Expression={$azr.ResourceName}}, `
                @{Name="ResourceType";Expression={$azr.ResourceType}}, `
                @{Name="PIMResourceID";Expression={$pim.ID}}, `
                @{Name="PIMRoleStatus";Expression={$pim.status}}, `
                @{Name="PIMRoleRegisteredDateTime";Expression={$pim.RegisteredDateTime}}, `
                @{Name="PIMRegisteredRoot";Expression={$pim.RegisteredRoot}}, `
                @{Name="RoleAssignmentId";Expression={$azra.RoleAssignmentId}}, `
                @{Name="RoleDefinitionName";Expression={$azra.RoleDefinitionName}}, `
                @{Name="MemberObjectID";Expression={$azra.objectid}}, `
                @{Name="MemberDisplayname";Expression={$azra.DisplayName}}, `
                @{Name="MemberSigninName";Expression={$azra.SignInName}}, `
                @{Name="MemberObjectType";Expression={$azra.ObjectType}}, `
                @{Name="PIMMemberStartDateTime";Expression={$member.StartDateTime}}, `
                @{Name="PIMMemberAssignmentState";Expression={$member.AssignmentState}}, `
                @{Name="PIMMemberType";Expression={$member.MemberType}}
        }
        if($pim){Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $pim.ID -pv azpra | where {$_.AssignmentState -eq "Eligible" -and $_.membertype -eq "Direct"} | foreach {
            $member = $null;$member = Get-AzureADObjectByObjectId -ObjectId $azpra.SubjectId
            $role = $null; $role = Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -id $azpra.RoleDefinitionId -ResourceId $azpra.ResourceId
            $azpra | select `
                @{Name="SubscriptionID";Expression={$azr.SubscriptionID}}, `
                @{Name="SubscriptionName";Expression={$azr.SubscriptionName}}, `
                @{Name="SubscriptionState";Expression={$azr.SubscriptionState}}, `
                @{Name="ResourceID";Expression={$azr.ResourceID}}, `
                @{Name="ResourceName";Expression={$azr.ResourceName}}, `
                @{Name="ResourceType";Expression={$azr.ResourceType}}, `
                @{Name="PIMResourceID";Expression={$pim.ID}}, `
                @{Name="PIMRoleStatus";Expression={$pim.status}}, `
                @{Name="PIMRoleRegisteredDateTime";Expression={$pim.RegisteredDateTime}}, `
                @{Name="PIMRegisteredRoot";Expression={$pim.RegisteredRoot}}, `
                @{Name="RoleAssignmentId";Expression={$role.ExternalId}}, `
                @{Name="RoleDefinitionName";Expression={$role.DisplayName}}, `
                @{Name="MemberObjectID";Expression={$azpra.SubjectId}}, `
                @{Name="MemberDisplayname";Expression={$member.DisplayName}}, `
                @{Name="MemberSigninName";Expression={$member.userprincipalname}}, `
                @{Name="MemberObjectType";Expression={$member.ObjectType}}, `
                @{Name="PIMMemberStartDateTime";Expression={$azpra.StartDateTime}}, `
                @{Name="PIMMemberAssignmentState";Expression={$azpra.AssignmentState}}, `
                @{Name="PIMMemberType";Expression={$azpra.MemberType}}
            }}
    }
    Write-Progress -activity "Enumerating Azure Resources" -Status "Enumerating" -Completed
}

Create-AZRBACResults | export-csv $report -notypeinformation
