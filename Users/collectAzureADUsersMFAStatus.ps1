#Requires -Module msonline
<#PSScriptInfo

.VERSION 0.1

.GUID 12882914-8e2c-491f-94cd-dddd2c9e1dce

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

.TAGS get-msoluser

.DESCRIPTION 
 Ensure that multi-factor authentication is enabled for all Azure AD users 

#> 
Param()

function getAllMSOLUsersMFAStatus{
    [CmdletBinding()]
    param()
    read-host "Press enter, then login with Account to query Azure Active Directory"
    #connect-msolservice
    $results = @()
    $AAD_Domains = get-msoldomain
    Set-Variable AAD_Domains -Scope Script
    #get all Azure AD Users. check MFA Status
    $results = get-MsolUser -all -PipelineVariable AADUser | foreach{
        #get users domain from the upn
        $userdomain = $AADUser.UserPrincipalName.split('@')[1]

        #create a hash table
        $hash = @{}
        $hash.mfaState = $AADUser.StrongAuthenticationRequirements.state
        $hash.AuthenticationType = ($aad_domains | where name -eq $userdomain).authentication
        $AADUser | select `
            UserPrincipalName,DisplayName,UserType,StsRefreshTokensValidFrom, `
            BlockCredential,LastDirSyncTime,ObjectId,
            @{Name="mfaState";Expression={$hash.mfaState}}, `
            @{Name="mfaMethod";Expression={$(if($_.StrongAuthenticationMethods){(`
                $_.StrongAuthenticationMethods | where IsDefault -eq $true).MethodType}else{"Not Defined"})}}, `
            @{Name="AuthenticationType";Expression={$hash.AuthenticationType}}, `
            @{Name="mfaStatus";Expression={whatisMFAResults -account $hash}}

    }
    return $results
}
Function whatisMFAResults{
    [CmdletBinding()]
    param($account)
    #should change this two param groups but lazy, or could change code, 
    #this function is used to determine status of the user's mfa
    write-information "Starting whatisMFAResults"
    if(($account.mfaState -eq "Enforced" -or $account.mfaState -eq "Enabled") -and `
        ($account.AuthenticationType -eq "Managed" -or $account.AuthenticationType -eq "Federated"))
    {
        return "Success"
    }elseif($account.AuthenticationType -eq "Federated"){
        return "Review"
    }else{
        return "Failed"
    }
}

getAllMSOLUsersMFAStatus
