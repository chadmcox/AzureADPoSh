
<#PSScriptInfo

.VERSION 0.1

.GUID 6a130530-ab1f-4c76-8884-86d23c5b74d0

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

.TAGS msonline PowerShell

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


.PRIVATEDATA 

#>

#Requires -Module azuread
#Requires -Version 4

<# 

.DESCRIPTION 
 This script compares primary smtp address with upn in azure ad. 

 Use the following command to update 
 find-module azuread | install-module

#> 
Param($path = "$env:USERPROFILE\Documents\")

connect-azuread

$results = "$($path)results_azureadusersupnmatchsmtp.csv"

$final_users = @()
$users = Get-AzureADUser -all $true | select userprincipalname, proxyaddresses
$users | where {$_.userprincipalname -notlike "*#EXT#@HoneywellProd.onmicrosoft.com" -and $_.proxyaddresses -like "*"} | `
    foreach{
    $primary_email = $null
    $primary_email = $_.proxyaddresses | foreach{if($_ -cmatch "SMTP:"){$_}}
    $primary_email = $primary_email -replace "SMTP:",""
    $final_users += $_ | select userprincipalname, `
        @{Name="PrimaryEmail";Expression={$primary_email}}, `
        @{Name="PrimaryEmailMatchUPN";Expression={if($primary_email -match $_.userprincipalname){$True}Else{$false}}}
}

write-host "Accounts with PrimaryEmail matching UPN" -foregroundcolor yellow
($final_users | where {$_.PrimaryEmailMatchUPN -eq $false -and $_.PrimaryEmail -contains "*"} | measure-object).count

$final_users | where {$_.PrimaryEmailMatchUPN -eq $false -and $_.PrimaryEmail -contains "*"} | export-csv $results -NoTypeInformation
Write-host "Results are here $results"
