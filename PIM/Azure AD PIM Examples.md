## Add User as elgible role in PIM
* List Azure AD PIM Roles
```
$ten = (Get-AzureADTenantDetail).objectid
Get-AzureADMSPrivilegedRoleDefinition -ProviderId "aadRoles" -ResourceId $ten

# In this example I am going to use Application Administrator, I find this in the list

Id                      : 9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3
ResourceId              : d9756784-046e-4a6a-a7a4-d053357dd76f
ExternalId              : 9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3
DisplayName             : Application Administrator
SubjectCount            : 
EligibleAssignmentCount : 
ActiveAssignmentCount   : 
```

* List current members of Role in PIM, will use the externalid from results previous cmdlet and use in the filter with roledefinitionid to this cmdlet.
```
Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $ten -filter "RoleDefinitionId eq '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'"

# returns several results smililar to this:

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
* Get the upn of the user you want to add to the role
```
get-azureaduser -ObjectId Anaya.Bradford@contoso.com | select objectid

ObjectId                            
--------                            
a240a3d2-50a9-49ca-8498-bb8f633ae46f

```
* The idea is to add this user as an elgible member in that role, the users objectid will be the subjectid
```
#create a generic schedule
$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$schedule.Type = "Once"

#create a open request


```
* [List of types](https://docs.microsoft.com/en-us/graph/api/governanceroleassignmentrequest-post?view=graph-rest-beta&tabs=http)
# Remove user as elgible role in PIM

