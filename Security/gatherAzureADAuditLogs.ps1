#https://techcommunity.microsoft.com/t5/azure-active-directory-identity/protecting-microsoft-365-from-on-premises-attacks/ba-p/1751754
#https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/reference-audit-activities

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Enable passthrough authentication'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Set DirSync feature'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Register connector'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Set domain authentication'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Set federation settings on domain'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Set password policy'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Enable password writeback for directory'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Add role definition'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={[string]($_).TargetResources.DisplayName}}

Get-AzureADAuditDirectoryLogs -Filter "Category eq 'RoleManagement' and ActivityDisplayName eq 'Add member to role'" -All $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={(($_.targetresources.ModifiedProperties | where {$_.DisplayName -eq "Role.DisplayName"}).newvalue).replace('"','')}}, `
    @{N="PrincipalName";E={if([string]($_).TargetResources.Displayname -notlike " "){[string]($_).TargetResources.Displayname}else{[string]($_).TargetResources.UserPrincipalName}}} | where {$_.InitiatedBy -ne 'MS-PIM'}

Get-AzureADAuditDirectoryLogs -Filter "Category eq 'RoleManagement' and ActivityDisplayName eq 'Add member to role outside of PIM (permanent)'" -All $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={if([string]($_).TargetResources.Displayname -notlike " "){[string]($_).TargetResources.Displayname}else{[string]($_).TargetResources.UserPrincipalName}}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Add conditional access policy'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={[string]($_).TargetResources.DisplayName}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Update conditional access policy'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={[string]($_).TargetResources.DisplayName}}

Get-AzureADAuditDirectoryLogs -Filter "Category eq 'ApplicationManagement' and OperationType eq 'Update'" -all $true | where {$_.ActivityDisplayName -like "*Update application – Certificates and secrets management*"} | `
    select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={[string]($_).TargetResources.DisplayName}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Add service principal credentials'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={[string]($_).TargetResources.DisplayName}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Add member to group'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={(($_.targetresources.ModifiedProperties | where {$_.DisplayName -eq "Group.DisplayName"}).newvalue).replace('"','')}}, `
    @{N="PrincipalName";E={[string]($_).TargetResources.UserPrincipalName}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Add user'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={[string]($_).TargetResources.UserPrincipalName}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Add app role assignment to service principal'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={[string]($_).TargetResources.DisplayName}}

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Add app role assignment grant to user'" -all $true | select ActivityDateTime, Result, ActivityDisplayName, `
    @{N="InitiatedBy";E={if($_.InitiatedBy.user.DisplayName){$_.InitiatedBy.user.DisplayName}elseif($_.InitiatedBy.app.DisplayName){$_.InitiatedBy.app.DisplayName}else{$_.InitiatedBy.user.UserPrincipalName}}}, `
    @{N="Target";E={[string]($_).TargetResources.DisplayName}}
