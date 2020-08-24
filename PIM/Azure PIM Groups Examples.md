## Here are some examples on how to use PowerShell and Privilaged Admin Groups

* Retrieve the objectid of the group you want to work with:
'''
PS C:\> get-azureadmsgroup -filter "displayname eq 'boguspag1'"

Id                                   DisplayName Description
--                                   ----------- -----------
266cc9ed-1522-4687-bae7-321bf578307a boguspag1 
``

* The ID of the group is the resourceid.
```
PS C:\> Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadGroups" -ResourceId 266cc9ed-1522-4687-bae7-321bf578307a

Id                             : 0b7a44d3-1109-4011-aff8-ea144d46a0da
ResourceId                     : 266cc9ed-1522-4687-bae7-321bf578307a
RoleDefinitionId               : 9669a865-0542-40be-8eeb-166c9a3acb1e
SubjectId                      : d639337d-2974-4485-92d7-abbf4c883b9a
LinkedEligibleRoleAssignmentId : 
ExternalId                     : 266cc9ed-1522-4687-bae7-321bf578307a_707A26F7-E617-480F-B112-673623E184E8_d639337d-2974-4485-92d7-abbf4c883b9a
StartDateTime                  : 8/21/2020 9:03:07 PM
EndDateTime                    : 2/17/2021 9:02:53 PM
AssignmentState                : Active
MemberType                     : Direct

Id                             : 5bc7dbc8-2a85-4863-a084-e2e433e45e26
ResourceId                     : 266cc9ed-1522-4687-bae7-321bf578307a
RoleDefinitionId               : 9669a865-0542-40be-8eeb-166c9a3acb1e
SubjectId                      : 659526d6-26c8-4189-a716-9c9bfd0aab6f
LinkedEligibleRoleAssignmentId : 
ExternalId                     : 
StartDateTime                  : 8/21/2020 8:58:02 PM
EndDateTime                    : 8/21/2021 8:57:36 PM
AssignmentState                : Eligible
MemberType                     : Direct
```
