#requires -module azureadpreview
<#PSScriptInfo

.VERSION 0.3

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
#>
Param($reportpath = "$env:userprofile\Documents")

#this is the same logic from the gatheraadsp collector,
$hash_ignore = @{Name="Ignore";Expression={if(($AADSP.serviceprincipaltype -eq "legacy") -or `
    ($AADSP.PublisherName -like "Microsoft*") -or ($AADSP.ServicePrincipalType -eq "ManagedIdentity")){$true}else{$False}}}

connect-azuread

#retrieve up to two permissiongrants from all applications
try{
    Write-host "Collecting Application Data from Azure AD. This could take a really long time." 
    try{$application_service_principals = Get-AzureADServicePrincipal -All $true}
    catch{throw $_.Exception}

    Write-host "Collecting Consent Data for each application from Azure AD. This will take a while"
    $application_service_principal_consents = foreach($aadsp in $application_service_principals){
        try{$aadsp | Get-AzureADServicePrincipalOAuth2PermissionGrant -top 2 -PipelineVariable PERMGrant |  select `
                @{Name="ServicePrincipalDisplayName";Expression={$AADSP.Displayname}}, `
                @{Name="ServicePrincipalObjectID";Expression={$AADSP.ObjectID}}, `
                @{Name="ServicePrincipalObjectType";Expression={$AADSP.ObjectType}}, `
                @{Name="AppDisplayName";Expression={$AADSP.AppDisplayName}}, `
                @{Name="AppId";Expression={$AADSP.AppId}}, `
                @{Name="PublisherName";Expression={$AADSP.PublisherName}}, `
                @{Name="AccountEnabled";Expression={$AADSP.AccountEnabled}}, `
                @{Name="ServicePrincipalType";Expression={$AADSP.ServicePrincipalType}},`
                ConsentType,ExpiryTime,PrincipalId,Scope,StartTime,$hash_ignore}
            catch{throw $_.Exception}
    }
    Write-host "Building Summary of Data"
    $summary = $application_service_principal_consents | where ignore -eq $false | select -expandproperty ServicePrincipalObjectID -Unique -PipelineVariable SpObjID | foreach{
        $all_grants_per_sp = $results | where ServicePrincipalObjectID -eq $SpObjID
        $all_grants_per_sp | select -First 1 | select ServicePrincipalDisplayName, ServicePrincipalObjectID, `
            ServicePrincipalObjectType, AppDisplayName, AppId, PublisherName, AccountEnabled, `
            ServicePrincipalType,ConsentType,ExpiryTime,Scope, `
            @{Name="ConsentCount";Expression={ `
                if(($all_grants_per_sp | measure-object).count -eq 1 -and $_.ConsentType -eq "Principal")
                    {"Single"}elseif($_.ConsentType -eq "Principal"){"Multiple"}}}
    }
}
catch{throw $_.Exception}
#summarize the permission grant

Write-host "Consented_by_Admin: $(($summary | where ConsentType -eq "AllPrincipals" | measure-object).count)"
Write-host "Consented_by_Single_User: $(($summary | where ConsentCount -eq "Single" | measure-object).count)"
Write-host "Consented_by_Multiple_Users: $(($summary | where ConsentCount -eq "Multiple" | measure-object).count)"
Write-host "Consented_with_Write_Scope_Defined: $(($summary | where {$_.ConsentType -eq "Principal" -and $_.Scope -like "*Write*"} | measure-object).count)"
Write-host "Exported data can be found here: $reportpath"
$summary | where ConsentType -eq "AllPrincipals" | export-csv "$reportpath\azuread_application_admin_consents.csv" -notypeinformation
$summary | where ConsentType -eq "Principal" | export-csv "$reportpath\azuread_application_user_consents.csv" -notypeinformation
$summary | export-csv "$reportpath\azuread_application_all_consents.csv" -notypeinformation
