#requires -module azureadpreview
<#PSScriptInfo

.VERSION 2019.6.19

.GUID 0e98504a-1173-4af8-a6ab-9564fdbadfa5

.AUTHOR Chad.Cox@microsoft.com
    https://blogs.technet.microsoft.com/chadcox/
    https://github.com/chadmcox

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
https://docs.microsoft.com/en-us/graph/api/resources/oauth2permissiongrant?view=graph-rest-beta

Added the
#>
Param($reportpath = "$env:userprofile\Documents")

#this is the same logic from the gatheraadsp collector,
$hash_ignore = @{Name="Ignore";Expression={if(($AADSP.serviceprincipaltype -eq "legacy") -or `
    ($AADSP.PublisherName -like "Microsoft*") -or ($AADSP.ServicePrincipalType -eq "ManagedIdentity")){$true}else{$False}}}

try{Get-AzureADCurrentSessionInfo}
catch{Connect-azuread}
cls
#retrieve up to two permissiongrants from all applications

Write-host "Collecting Application Service Principals from AAD." 
$time_to_run = measure-command {try{$application_service_principals = Get-AzureADServicePrincipal -Filter "serviceprincipaltype eq 'Application'" -All $true} 
catch{throw $_.Exception}}
Write-host "Completed $($time_to_run.minutes) minutes"
$count = $application_service_principals.count; $i = 1
Write-host "Collecting Consent Data for each application from Azure AD. This will take a while"
$time_to_run = measure-command {$summary = $application_service_principals | select -PipelineVariable aadsp | foreach { 
    write-host "$i of $count : Gathering Consent for $($AADSP.AppDisplayName)"; $i++
    $all_grants_per_sp =  $aadsp | Get-AzureADServicePrincipalOAuth2PermissionGrant -top 2 -PipelineVariable PERMGrant
    $all_grants_per_sp | select @{Name="ServicePrincipalDisplayName";Expression={$AADSP.Displayname}}, `
        @{Name="ServicePrincipalObjectID";Expression={$AADSP.ObjectID}}, `
        @{Name="ServicePrincipalObjectType";Expression={$AADSP.ObjectType}}, `
        @{Name="AppDisplayName";Expression={$AADSP.AppDisplayName}}, `
        @{Name="AppId";Expression={$AADSP.AppId}}, `
        @{Name="PublisherName";Expression={$AADSP.PublisherName}}, `
        @{Name="AccountEnabled";Expression={$AADSP.AccountEnabled}}, `
        @{Name="ServicePrincipalType";Expression={$AADSP.ServicePrincipalType}},` 
            ConsentType,ExpiryTime,Scope, `
            @{Name="ConsentCount";Expression={ `
            if(($all_grants_per_sp | measure-object).count -eq 1 -and $_.ConsentType -eq "Principal")
                {"Single"}elseif($_.ConsentType -eq "Principal"){"Multiple"}}} -First 1 
}}

cls
Write-host "Completed $($time_to_run.hours) hours $($time_to_run.minutes) minutes"

write-host "-----Summary-----"
Write-host "Consented_by_Admin: $(($summary | where ConsentType -eq "AllPrincipals" | measure-object).count)"
Write-host "Consented_by_Single_User: $(($summary | where ConsentCount -eq "Single" | measure-object).count)"
Write-host "Consented_by_Multiple_Users: $(($summary | where ConsentCount -eq "Multiple" | measure-object).count)"
Write-host "Consented_with_Write_Scope_Defined: $(($summary | where {$_.Scope -like "*Write*"} | measure-object).count)"
#nice write up on the topic of admin perms
#https://itconnect.uw.edu/wares/msinf/aad/apps/risky-aad-app-perms/
Write-host "Risky_Consented_with_Read_Hidden_Memberships_Defined: $(($summary | where {$_.Scope -like "*Member.Read.Hidden*"} | measure-object).count)"
Write-host "Risky_Consented_with_Read_All_Users_Full_Profile_Defined: $(($summary | where {$_.Scope -like "*User.Read.All*"} | measure-object).count)"
Write-host "Risky_Consented_with_Read_All_Groups_Defined: $(($summary | where {$_.Scope -like "*Group.Read.All*"} | measure-object).count)"
Write-host "Risky_Consented_with_Write_All_Groups_Defined: $(($summary | where {$_.Scope -like "*Group.Write.All*"} | measure-object).count)"
Write-host "Risky_Consented_with_Read_Write_All_Directory_Data_Defined: $(($summary | where {$_.Scope -like "*Directory.ReadWrite.All*"} | measure-object).count)"
Write-host "Risky_Consented_with_Read_All_Directory_Data_Defined: $(($summary | where {$_.Scope -like "*Directory.Read.All*"} | measure-object).count)"
Write-host "Exported data can be found here: $reportpath"
$summary | where ConsentType -eq "AllPrincipals" | export-csv "$reportpath\azuread_application_admin_consents.csv" -notypeinformation
$summary | where ConsentType -eq "Principal" | export-csv "$reportpath\azuread_application_user_consents.csv" -notypeinformation
$summary | export-csv "$reportpath\azuread_application_all_consents.csv" -notypeinformation
