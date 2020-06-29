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
    foreach($azr in $azureResources){
        $pim = $null;$pim = Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$(($azr).ResourceID)'"
        Get-AzRoleAssignment -scope $azr.ResourceID -pv azra | where {$azra.Scope -eq $azr.ResourceID} | foreach{
            $member = $null;$member = Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $pim.ID -Filter "externalId eq '$(($azra).RoleAssignmentId)'"
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
    }
}


Create-AZRBACResults | export-csv 
