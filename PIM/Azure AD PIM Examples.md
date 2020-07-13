## Add User as elgible role in PIM
* List Azure AD PIM Roles
```
$ten = (Get-AzureADTenantDetail).objectid
Get-AzureADMSPrivilegedRoleDefinition -ProviderId "aadRoles" -ResourceId $ten
```
* in this example I am going to use Application Administrator, I find this in the list
'''
Id                      : 9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3
ResourceId              : d9756784-046e-4a6a-a7a4-d053357dd76f
ExternalId              : 9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3
DisplayName             : Application Administrator
SubjectCount            : 
EligibleAssignmentCount : 
ActiveAssignmentCount   : 
```

* List current members of Role in PIM
```
Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $ten -filter "RoleDefinitionId eq '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'"
```
* will return several results smililar to this:
```
Id                             : kl2Jm9Msx0SdAqasLV6lw-wUMae3_0VKuCPzYLT6u7c-1
ResourceId                     : d9756784-046e-4a6a-a7a4-d053357dd76f
RoleDefinitionId               : 9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3
SubjectId                      : a73114ec-ffb7-4a45-b823-f360b4fabbb7
LinkedEligibleRoleAssignmentId : 
ExternalId                     : kl2Jm9Msx0SdAqasLV6lw-wUMae3_0VKuCPzYLT6u7c-1
StartDateTime                  : 
EndDateTime                    : 
AssignmentState                : Active
MemberType                     : Direct
```




#remove user as elgible role in PIM

