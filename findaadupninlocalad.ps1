#Require -module MSonline
#Require -module activedirectory
<#PSScriptInfo

.VERSION 0.4

.GUID 5e7bfd24-88b8-4e4d-99fd-c4ffbfcf5be6

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

.description

#>
Param($reportpath = "$env:userprofile\Documents")
#Connect-MsolService
cls
$mismatched_users = @()

function searchforupn{
    param($upn)
    foreach($adupn in $adusers_upns){
        if($aadupn -eq $adupn){
            Return $true
            exit
        }
    }
    return $false
}
function searchforproxy{
    param($upn)
    foreach($aduser in $adusers){
        if($aduser.proxyaddress -like "*$aadupn*"){
            Return $aduser
            exit
        }
    }
    $upn | select @{name="userprincipalname";Expression={$upn}}, `
            @{name="proxyaddress";Expression={"Not Found"}}
}

Write-host "Gathering Synced Licensed Users from AAD"
#$aadusers_upns = (Get-MsolUser -Synchronized -all | where {$_.isLicensed -eq $true} | select Userprincipalname).Userprincipalname
#$aadusers_upns = (Get-MsolUser -Synchronized -all | select Userprincipalname).Userprincipalname
$adusers = @()
Write-host "Gathering Users from AD"
foreach($domain in (get-adforest).domains){
    Write-host "Gathering users from $domain"
    $adusers += get-aduser -ldapfilter "(proxyaddresses=*)" -server $domain -pipelinevariable aduser `
        -properties proxyaddresses | select -ExpandProperty proxyaddresses -PipelineVariable pa | foreach {
            $aduser | select userprincipalname, `
            @{name="proxyaddress";Expression={$pa}}
        }
}

write-host "Creating Unique List of UPNs for AD Users"
$adusers = $adusers | sort
$adusers_upns = ($adusers | select userprincipalname -Unique).userprincipalname
$aadusers_upns = $aadusers_upns | sort
write-host "Retrieved $(($aadusers_upns | Measure-Object).count) UPNs from AAD"
write-host "Retrieved $(($adusers | Measure-Object).count) Unique Proxy Entries from AD"
write-host "Retrieved $(($adusers_upns | Measure-Object).count) Unique UPN from AD"


foreach($aadupn in $aadusers_upns){
    if(!(searchforupn -upn $aadupn)){
        Write-host "UPN Not Found: $aadupn"
        $mismatched_users += searchforproxy -upn $aadupn
    }
}

$mismatched_users | export-csv "$reportpath\aaduserswithmismatchedupn.csv" -NoTypeInformation
write-host "Found Users with Mismatched UPN in AD Total: $(($mismatched_users | Measure-Object).count)"
