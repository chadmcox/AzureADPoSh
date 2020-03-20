Get-AzureADAuditDirectoryLogs -Filter "Category eq 'ApplicationManagement'" | where {$_.activityDisplayName -in "Add service principal credentials","Update application – Certificates and secrets management","Update external secrets"} | select `
    ActivityDateTime,ActivityDisplayName,@{Name="ModifiedBy";Expression={$_.InitiatedBy.user.UserPrincipalName}}, `
    @{Name="ID";Expression={$_.TargetResources.ID}}, `
    @{Name="Displayname";Expression={$_.TargetResources.displayname}}, `
    @{Name="type";Expression={$_.TargetResources.type}}
