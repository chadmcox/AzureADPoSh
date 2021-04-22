
<#PSScriptInfo

.VERSION 0.1

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

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


.PRIVATEDATA 

#>

#Requires -Module AzureAD

<# 

.DESCRIPTION 
 This Script will List all the registered application's password expiration date in an Azure AD Instance. 

#> 
Param($reportpath = "$env:userprofile\Documents")

$default_log = "$reportpath\report_AzureADApplicationExpirationDate.csv"

#only prompt for connection if needed
try{Get-AzureADCurrentSessionInfo}
catch{Connect-azuread}

$results = @()
foreach($AADapp in Get-AzureADApplication){
    $results += Get-AzureADApplicationPasswordCredential -objectid $AADapp.objectid | select `
        @{name='ObjectID';expression={$AADapp.objectid}},KeyId, `
        @{name='DisplayName';expression={$AADapp.DisplayName}},StartDate,EndDate, `
        @{name='Expired';expression={if($_.EndDate -lt $(get-date)){$true}}}
}

$results | export-csv $default_log -NoTypeInformation
$results | sort enddate

<#
   Sample code
    $newkeys = @()
    foreach($key in ($Results | where {$_.Expired -eq $true})){
        #create a new Key can add a startdate, enddate, customkeyidentifier as well
        $newkeys += New-AzureADApplicationPasswordCredential -objectid $_.ObjectID
        #delete the old Key
        Remove-AzureADApplicationPasswordCredential -ObjectId $_.objectid -keyid $_.keyid
    } 
    $newkeys
#>
