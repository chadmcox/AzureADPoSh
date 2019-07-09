#requires -modules msonline,azureadpreview
#requires -version 4
<#PSScriptInfo

.VERSION 2019.6.19

.GUID 368e7248-347a-46d9-ba35-3ae42890daed

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
#>
param($reportpath="$env:userprofile\Documents")
$report = "$reportpath\AAD_AppRoleMembers_$((Get-AzureADTenantDetail).DisplayName)_$(get-date -f yyyy-MM-dd-HH-mm).csv"

#only prompt for connection if needed
try{Get-AzureADCurrentSessionInfo}
catch{Connect-azuread}

Function gatherAADSPRoles{
#get all approles from service principals that can contain users
        Get-AzureADServicePrincipal -Filter "serviceprincipaltype eq 'Application'" -All $true -PipelineVariable AADSP | `
            where {$_.AppRoles.AllowedMemberTypes -eq "User"} | foreach {
            $aadsp.AppRoles | select `
                @{Name="AssignedToDisplayName";Expression={$AADSP.Displayname}}, `
                @{Name="AssignedToObjectID";Expression={$AADSP.ObjectID}}, `
                @{Name="ObjectType";Expression={$AADSP.ObjectType}}, `
                @{Name="PublisherName";Expression={$AADSP.PublisherName}}, `
                @{Name="AppRoleAssignmentRequired";Expression={$AADSP.AppRoleAssignmentRequired}}, `
                @{Name="AccountEnabled";Expression={$AADSP.AccountEnabled}}, `
                @{Name="AllowedMemberTypes";Expression={[string]($_).AllowedMemberTypes}}, `
                Description,Displayname,ID,isenabled,value
        }
}
function hashroles{
    $hash = @{}
    $roles | foreach {$hash[$_.Id] = @{Description=$_.Description;DisplayName=$_.displayName;Value=$_.value;isEnabled=$_.isenabled}}
    return $hash
}

$roles = @()
$roles = gatherAADSPRoles
#consolidate to unique values
$roles = $roles | select id, isenabled, Displayname, Description, Value -Unique
#hash unique entries
$hashedroles =  hashroles

#retrieves a list of sp that are tied to application type instead of legacy
$AzureADSPs = Get-AzureADServicePrincipal -Filter "serviceprincipaltype eq 'Application'" -All $true | `
    where {$_.AppRoles.AllowedMemberTypes -eq "User"}
#this filter where {$_.AppRoles.AllowedMemberTypes -eq "User"}
#is used to determine where user assigned roles are possible
foreach($sp in $azureADSPs){
    #write-host "$(get-date) - $($sp.AppDisplayName)"
    Get-AzureADServiceAppRoleassignment -ObjectID $sp.objectid -All $true -PipelineVariable AADSAR | select `
    ResourceDisplayName, ResourceId, PrincipalDisplayName, PrincipalID, PrincipalType, CreationTimestamp, `
    @{Name="RoleID";Expression={$($AADSAR).id}}, `
    @{Name="RoleDisplayName";Expression={if(($AADSAR).id -ne '00000000-0000-0000-0000-000000000000'){$hashedroles[$(($AADSAR).id)].Displayname}else{"Default Access"}}}, `
    @{Name="RoleValue";Expression={$hashedroles[$(($AADSAR).id)].value}}, `
    @{Name="RoleDescription";Expression={$hashedroles[$(($AADSAR).id)].description}}
} | export-csv $report -NoTypeInformation
