#Require -module MSonline
#Require -module activedirectory
<#PSScriptInfo

.VERSION 0.3

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
Connect-MsolService

#needs to connect to global catalog
$domain = (get-addomain).DNSRoot + ":3268"

get-job | Remove-Job -Force


$MaxThreads = 3
$SleepTimer = 500
$jobnumber = 1

Write-host "Gathering Synced Licensed Users from AAD"
$aadusers_upns = (Get-MsolUser -Synchronized -all | where {$_.isLicensed -eq $true} | select Userprincipalname).Userprincipalname
#$aadusers_upns = (Get-MsolUser -Synchronized -all | select Userprincipalname).Userprincipalname

Write-host "Searching Local AD"
foreach($upn in $aadusers_upns){
    While (@(Get-Job -state running).count -ge $MaxThreads){      
        Start-Sleep -Milliseconds $SleepTimer
    }
    write-host "$(($upn).userprincipalname)"
    Start-Job -scriptblock {
        $aadupn = $args[0]
        $report = $args[1]
        $domain = $args[2]
        
        $results = get-aduser -Filter {Userprincipalname -eq $aadupn} -server $domain

        if(!($results)){
            $search_upn = "*$aadupn*"
            $proxy_upn = (get-aduser -Filter {proxyaddresses -like $search_upn} -server $domain -properties Userprincipalname).Userprincipalname
            $aadupn | select  `
            @{name='Userprincipalname';expression={$aadupn}}, `
            @{name='NewUpn';expression={if($proxy_upn){$proxy_upn}else{"Not Found"}}} 
        }else{
            $aadupn | select  `
            @{name='Userprincipalname';expression={$aadupn}}, `
            @{name='NewUpn';expression={"Found"}}
        }

    } -ArgumentList $upn,$reportpath,$domain -Name $upn

}

While (Get-Job -state running){      
        Start-Sleep -Milliseconds $SleepTimer
}

$results = Receive-Job * | select Userprincipalname,NewUpn

$results | where newupn -ne "Found" | export-csv "$reportpath\aaduserswithmismatchedupn.csv" -NoTypeInformation


#$mismatched_users | export-csv "$reportpath\aaduserswithmismatchedupn.csv" -NoTypeInformation
write-host "Found Users with Mismatched UPN in AD Total: $(($mismatched_users | Measure-Object).count)"
