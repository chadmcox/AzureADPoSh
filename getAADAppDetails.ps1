<#PSScriptInfo

.VERSION 2019.3.7

.GUID e7a48d24-7c7a-4a21-b32d-2a86c844b90a

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

.TAGS Get-AzureRmContext Set-AzureRmContext Get-AzureRmRoleAssignment

.DETAILS

.EXAMPLE


#>

param($reportpath="$env:userprofile\Documents")


function isconsentbad{
    param($scopes)
    $riskyconsents = @("Write","Member.Read.Hidden","User.Read.All","Member.Read.Hidden", `
        "Group.Read.All","Directory.Read.All","Mail","Calendar")
    foreach($rs in $riskyconsents){
          if($scopes -match $rs){
            return $true;exit
          }
    }
}


$report = "$reportpath\AAD_APPsp_$((Get-AzureADTenantDetail).DisplayName)_$(get-date -f yyyy-MM-dd-HH-mm).csv"

write-host "Building app sign in hash table"
$azureadappsignin = Get-AzureADApplicationSignInSummary -days 30

$hash_appsignin = @{}
$azureadappsignin | foreach {
    $hash_appsignin += @{($_).id = @{'SuccessfulSignInCount' = "$($_.SuccessfulSignInCount)"
    'FailedSignInCount' = "$($_.FailedSignInCount)"
    'SuccessPercentage' = "$($_.SuccessPercentage )"}}
}
write-host "Building app lookup hash table"
$aadapps = Get-AzureADApplication -all $true
$hash_apps = @{}
$aadapps | foreach {
    $hash_apps += @{($_).appid = @{'SignInAudience' = "$($_.SignInAudience)"
    'Oauth2AllowImplicitFlow' = "$($_.Oauth2AllowImplicitFlow)"
    'AvailableToOtherTenants' = "$($_.AvailableToOtherTenants)"}}
}


$hash_ignore = @{Name="Ignore";Expression={if(($aadsp.replyurls -like "*.sharepoint.com*" `
    -and $aadsp.serviceprincipaltype -eq "legacy") -or (($aadsp.PublisherName -like "Microsoft*") -and ($aadsp.PublisherName -notlike "Microsoft Accounts")) `
    -or ($aadsp.ServicePrincipalType -eq "ManagedIdentity")){$true}else{$False}}}

write-host "Getting every security principal"
$aadsps = get-azureadserviceprincipal -all $true

write-host "Building Report - this will take a while"
@(foreach($aadsp in $aadsps){
    $grants = $aadsp | where serviceprincipaltype -eq 'Application' | Get-AzureADServicePrincipalOAuth2PermissionGrant -top 4
    $aadsp | select objectid,appId, displayname,ServicePrincipalType ,PublisherName,AccountEnabled,$hash_ignore,Homepage, `
    @{N="keyCredentialsExpirationDate";E={$aadsp.keycredentials.enddate | sort -Descending | select -First 1}}, `
    @{N="PwdCredentialsExpirationDate";E={$aadsp.passwordcredentials.enddate | sort -Descending | select -First 1}}, `
    @{N="OwnerDefined";E={[string]$((Get-AzureADServicePrincipalOwner -ObjectId $aadsp.ObjectId).UserPrincipalName)}}, `
    @{N="isEnterpriseApplication";E={if($aadsp.tags -contains 'WindowsAzureActiveDirectoryIntegratedApp'){$true}else{$false}}}, `
    @{N="AllowedMemberType";E={($grants | select -first 1).ConsentType}},AppRoleAssignmentRequired, `
    @{N="AllowedAppRoleMemberType";E={[string]$($_.AppRoles | select -expandproperty AllowedMemberTypes -Unique)}}, `
    @{N="SignInAudience";E={($hash_apps[$aadsp.appid]).SignInAudience}}, `
    @{N="Oauth2AllowImplicitFlow";E={($hash_apps[$aadsp.appid]).Oauth2AllowImplicitFlow}}, `
    @{N="AvailableToOtherTenants";E={($hash_apps[$aadsp.appid]).AvailableToOtherTenants}}, `
    @{N="ConsentType";E={($grants | select -first 1).ConsentType}}, `
    @{N="RiskyConsent";E={if($grants){isconsentbad -scopes $grants.scope}}}, `
    @{N="ConsentUserCount";E={if(($grants | measure-object).count -eq 1 -and $grants.ConsentType -eq "Principal")
        {"Single"}elseif($grants.ConsentType -eq "Principal"){"Multiple"}}}, `
    @{N="AppRightsDefined";E={if($aadsp.AppRoles){$true}else{$false}}}, `
    @{N="DelegatedRightsDefined";E={if($aadsp.Oauth2Permissions){$true}else{$false}}}, `
    @{N="SuccessfulSignInCount";E={($hash_appsignin[$aadsp.appid]).SuccessfulSignInCount}}, `
    @{N="FailedSignInCount";E={($hash_appsignin[$aadsp.appid]).FailedSignInCount}}, `
    @{N="SuccessPercentage";E={($hash_appsignin[$aadsp.appid]).SuccessPercentage}}<#, `
    @{N="tags";E={[string]$($aadsp | select -expandproperty tags)}}#>}) | `
export-csv $report -NoTypeInformation

write-host "Report location: $report"
