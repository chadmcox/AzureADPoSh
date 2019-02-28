#Require -module MSonline
#Require -module activedirectory
<#PSScriptInfo

.VERSION 0.10

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
Param($days=15,$reportpath = "$env:userprofile\Documents")
Connect-MsolService
$changes_in_days = [DateTime]::Today.AddDays(-$days) 
$changes_in_days = (get-date).Adddays(-($days))

function searchAADforUPN{
    param($upn)
    if(get-msoluser -UserPrincipalName $upn){
        Write-host "$upn found in Azure AD"
        $true
    }else{
        $false
        Write-host "$upn not found in Azure AD"
    }
}
$time = Measure-Command -Expression { `
$ad_users = get-adforest | select -ExpandProperty domains -PipelineVariable domain | foreach{
    Write-host "Collecting Users from $domain"
    get-aduser -ldapfilter "(proxyaddresses=*)" `
        -server $domain -properties "msDS-ReplAttributeMetaData",userprincipalname,proxyaddresses | select `
        @{name='Domain';expression={$domain}},userprincipalname,samaccountname,"msDS-ReplAttributeMetaData",proxyaddresses
}} | select minutes
            
Write-host "AD Query Time $(($time).minutes) minutes"
Write-host "Filtering out objects with no upn or proxy change in last $changes_in_days days"
$time = Measure-Command -Expression { `
    $ad_users_changed = $ad_users | select domain,userprincipalname,proxyaddresses, `
            @{name='ProxyAddressChangeDate';expression={($_ | `
                Select-Object -ExpandProperty "msDS-ReplAttributeMetaData" | foreach {([XML]$_.Replace("`0","")).DS_REPL_ATTR_META_DATA |`
                where { $_.pszAttributeName -eq "proxyaddresses"}}).ftimeLastOriginatingChange | get-date}}, `
            @{name='UPNChangeDate';expression={($_ | `
                Select-Object -ExpandProperty "msDS-ReplAttributeMetaData" | foreach {([XML]$_.Replace("`0","")).DS_REPL_ATTR_META_DATA |`
                where { $_.pszAttributeName -eq "UserPrincipalname"}}).ftimeLastOriginatingChange | get-date}} | `
                where {($_.UPNChangeDate -gt $changes_in_days) -or ($_.ProxyAddressChangeDate -gt $changes_in_days)}
} | select minutes
 Write-host "UPN Filter Time $(($time).minutes) minutes"
 write-host "Found $(($ad_users_changed  | measure-Object).count) Users with UPN Changed in last $changes_in_days days"
 Write-host "Validate Objects exist in Azure AD"
 $results = @()
 foreach($adu in $ad_users_changed){
    if(!(searchAADforUPN -upn ($adu).userprincipalname)){
        $adu | select -ExpandProperty proxyaddresses -PipelineVariable proxy | foreach {
            if(searchAADforUPN -upn $(($proxy -split ":")[1])){
                $results += $adu | select userprincipalname, UPNChangeDate,ProxyAddressChangeDate, `
                            @{name='AADUPN';expression={$(($proxy -split ":")[1])}}
            }
        }
    }
 }
 

 $ad_users_changed | select domain,userprincipalname,ProxyAddressChangeDate,UPNChangeDate  | export-csv "$reportpath\upnchanged.csv" -NoTypeInformation
 $results | export-csv "$reportpath\upnnotfoundinaad.csv" -NoTypeInformation
