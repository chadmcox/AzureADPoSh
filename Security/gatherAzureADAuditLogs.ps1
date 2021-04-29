#https://techcommunity.microsoft.com/t5/azure-active-directory-identity/protecting-microsoft-365-from-on-premises-attacks/ba-p/1751754
#https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/reference-audit-activities

Get-AzureADAuditDirectoryLogs -Filter "category eq 'DirectoryManagement'"

Get-AzureADAuditDirectoryLogs -Filter "category eq 'DirectoryManagement' and ActivityDisplayName eq 'Enable passthrough authentication'"

Get-AzureADAuditDirectoryLogs -Filter "category eq 'DirectoryManagement' and ActivityDisplayName eq 'Set DirSync feature'"

Get-AzureADAuditDirectoryLogs -Filter "category eq 'ResourceManagement' and ActivityDisplayName eq 'Register connector'"

Get-AzureADAuditDirectoryLogs -Filter "category eq 'Resource' and ActivityDisplayName eq 'Set domain authentication'"

Get-AzureADAuditDirectoryLogs -Filter "category eq 'Resource' and ActivityDisplayName eq 'Set federation settings on domain'"

Get-AzureADAuditDirectoryLogs -Filter "category eq 'Resource' and ActivityDisplayName eq 'Set password policy'"

Get-AzureADAuditDirectoryLogs -Filter "category eq 'Resource' and ActivityDisplayName eq 'Set DirSync feature'"

Get-AzureADAuditDirectoryLogs -Filter "category eq 'Resource' and ActivityDisplayName eq 'Enable password writeback for directory'"

Get-AzureADAuditDirectoryLogs -Filter "ActivityDisplayName eq 'Add role definition'"




Add service principal credentials.
Update application- certificates and secrets management.
Update service principal.
Add app role assignment to service principal.
Add app role assignment grant to user.
Add OAuth2PermissionGrant.
Group membership changes
New user account creation
New Custom Roles
Updates to custom roles


Get-AzureADApplicationProxyApplication
