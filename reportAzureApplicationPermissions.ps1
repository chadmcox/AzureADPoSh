#Requires -modules AzureADPreview
<#PSScriptInfo

.VERSION 2020.3.9

.GUID 657fdc2d-4d6d-4370-a5ac-3244715349d1

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

.TAGS Azure Active Directory PowerShell

.DESCRIPTION 
 #collect Application Direct and Delegated Permissions
#> 
Param($reportpath = "$env:userprofile\Documents")

$report = "$reportpath\report_AzureADDelegatedandAssignedPermissions.csv"

#connect-azuread

$approles = Get-AzureADServicePrincipal -All $true -pv aadsp | select -ExpandProperty approles | select `
        @{Name="appID";Expression={$aadsp.appid}},@{Name="ObjectID";Expression={$_.id}},DisplayName,IsEnabled,value
$approles += Get-AzureADServicePrincipal -All $true -pv aadsp | select -ExpandProperty Oauth2Permissions | select `
        @{Name="appID";Expression={$aadsp.appid}},@{Name="ObjectID";Expression={$_.id}},@{Name="Displayname";Expression={$_.UserConsentDisplayName}},IsEnabled,value
$hash = $approles | group objectid -AsHashTable -AsString
Get-AzureADapplication -All $true -pv aadapp | select -ExpandProperty RequiredResourceAccess -pv rra | select -ExpandProperty ResourceAccess | select `
    @{N="APPID";E={$aadapp.appid}},@{N="APPDisplayname";E={$aadapp.displayname}},Type,@{Name="PermissionDisplayname";Expression={$hash[($_).id].displayname | select -first 1}}, `
    @{Name="Permission";Expression={$hash[($_).id].value | select -first 1}} | export-csv $report -NoTypeInformation

