
## Add a Management Group, Subscription, Resource Group to be managed by PIM

```
PS C:\Temp> $externalid = "/subscriptions/3e49b46f-ac28-4654-8694-6ee0dc924fd1"
Add-AzureADMSPrivilegedResource -ProviderId AzureResources -ExternalId $externalid

```

##R etrieve the PIM resource ID
Using the outvariable, going to store the object in the resourceid variable

```
PS C:\TEMP> Get-AzureADMSPrivilegedResource -ProviderId AzureResources -filter "externalId eq '$externalid'" -OutVariable resourceid


Id                  : 78f5d166-4730-4ae7-affe-1c9abb817a98
ExternalId          : /subscriptions/3e49b46f-ac28-4654-8694-6ee0dc924fd1
Type                : subscription
DisplayName         : Visual Studio Ultimate with MSDN
Status              : Active
RegisteredDateTime  : 10/9/2020 6:17:33 PM
RegisteredRoot      : 
RoleAssignmentCount : 
RoleDefinitionCount : 
Permissions         : 
```

## Retrieve the role definitions.
For this example going to work with the contributor role, will use the where clause to only retrieve that object and will store in a variable called contributor.
```
PS C:\Temp> Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $resourceid.id | where displayname -eq "Contributor" -OutVariable Contributor


Id                      : b0d08d34-03d8-4e23-866b-cb6c88696dbd
ResourceId              : 78f5d166-4730-4ae7-affe-1c9abb817a98
ExternalId              : /subscriptions/3e49b46f-ac28-4654-8694-6ee0dc924fd1/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c
DisplayName             : Contributor
SubjectCount            : 
EligibleAssignmentCount : 
ActiveAssignmentCount   : 
```

# To view the current members of the contributor role and their status

```
PS C:\Temp> Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -ResourceId $resourceid.id -filter "RoledefinitionId eq '$($Contributor.id)'"


Id                             : 39a43e7e-7c29-43fe-9be7-7a2d593c8cf9
ResourceId                     : 78f5d166-4730-4ae7-affe-1c9abb817a98
RoleDefinitionId               : b0d08d34-03d8-4e23-866b-cb6c88696dbd
SubjectId                      : b0876644-0a73-4105-bab2-8a346aaca72d
LinkedEligibleRoleAssignmentId : 
ExternalId                     : /subscriptions/3e49b46f-ac28-4654-8694-6ee0dc924fd1/providers/Microsoft.Authorization/roleAssignments/39a43e7e-7c29-43fe-9be7-7a2d593c8cf9
StartDateTime                  : 
EndDateTime                    : 
AssignmentState                : Active
MemberType                     : Direct
```
The subjectid is the objectid for the user
```
PS C:\Temp> Get-AzureADObjectByObjectId -ObjectIds b0876644-0a73-4105-bab2-8a346aaca72d

ObjectId                             DisplayName  UserPrincipalName                        UserType
--------                             -----------  -----------------                        --------
b0876644-0a73-4105-bab2-8a346aaca72d Alison Kirby Alison.Kirby@M365x437870.onmicrosoft.com Member  
```

# Change Active Assignment to Eligible
Have to create a schedule object to include with the request.  This can be used to control things like how long someone is alloweds to have access to a role for.  The schedule I have here is just a generic schedule.
```
PS C:\Temp> $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule

PS C:\Temp> $schedule.Type = "Once"

PS C:\Temp> Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId AzureResources -ResourceId $resourceid.id `
            -RoleDefinitionId $Contributor.id -SubjectId "b0876644-0a73-4105-bab2-8a346aaca72d" `
            -Type "AdminUpdate" -assignmentState "Eligible" -Schedule $schedule


ResourceId       : 78f5d166-4730-4ae7-affe-1c9abb817a98
RoleDefinitionId : b0d08d34-03d8-4e23-866b-cb6c88696dbd
SubjectId        : b0876644-0a73-4105-bab2-8a346aaca72d
Type             : AdminUpdate
AssignmentState  : Eligible
Schedule         : class AzureADMSPrivilegedSchedule {
                     StartDateTime: 10/12/2020 3:58:14 PM
                     EndDateTime: 
                     Type: Once
                     Duration: PT0S
                   }
                   
Reason           : 
```
## Add a new elgible assignment
```
PS C:\Temp> Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId AzureResources -ResourceId $resourceid.id `
            -RoleDefinitionId $Contributor.id -SubjectId "d2ea07f0-fce5-42cc-a12f-5e9d45d22570" `
            -Type "AdminAdd" -assignmentState "Eligible" -Schedule $schedule


ResourceId       : 78f5d166-4730-4ae7-affe-1c9abb817a98
RoleDefinitionId : b0d08d34-03d8-4e23-866b-cb6c88696dbd
SubjectId        : d2ea07f0-fce5-42cc-a12f-5e9d45d22570
Type             : AdminAdd
AssignmentState  : Eligible
Schedule         : class AzureADMSPrivilegedSchedule {
                     StartDateTime: 10/12/2020 4:01:48 PM
                     EndDateTime: 
                     Type: Once
                     Duration: PT0S
                   }
                   
Reason           : 
```

