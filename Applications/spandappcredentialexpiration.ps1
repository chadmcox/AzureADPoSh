#Requires -module AzureADPreview
#Requires -version 3.0
<#PSScriptInfo

.VERSION 2019.11.21.1

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



#>
param($reportpath="$ENV:Userprofile\Documents")



function getcredentialdate{
    param($displayname,$objectid,$objecttype,$credential,$credtype,$credcount,$allcreds,$owner,$replyurls,$homepage)
        $credential | select `
            @{Name="DisplayName";Expression={$displayname}} , `
            @{Name="ObjectID";Expression={$objectid}} , `
            @{Name="ObjectType";Expression={$objecttype}} , `
            startdate,enddate,keyid,type, `
            @{Name="CountofCreds";Expression={$credcount}} , `
            @{Name="Expired";Expression={if($_.enddate -lt (get-date).DateTime){$true}else{$False}}}, `
            @{Name="ExpiredinDays";Expression={(new-TimeSpan($(Get-Date)) $_.enddate).days}}, `
            @{Name="AllCredsExpired";Expression={$allcreds}}, `
            @{Name="Owner";Expression={$owner}}, `
            @{Name="replyurls";Expression={$replyurls}}, `
            @{Name="homepage";Expression={$homepage}}
}
function getowner{
    param($objectid,$objecttype)
    if($objecttype -eq "Application"){
        $return = Get-AzureADApplicationOwner -ObjectId $objectid
    }else{
        $return = Get-AzureADServicePrincipalOwner -ObjectId $objectid
    }

    if($return){$return[0].UserPrincipalName}
}
function getSPandAPP{
    write-host "Retrieving SP Creds"
    Get-AzureADServicePrincipal -All $true -PipelineVariable aadsp | `
        where {($_.serviceprincipaltype -in "Application","Legacy") -and ($_.PasswordCredentials -like "*" -or $_.keycredentials -like "*")}  
    write-host "Retrieving APP Creds"
    get-azureadapplication -all $true -PipelineVariable aadapp | `
        where {($_.PasswordCredentials -like "*" -or $_.keycredentials -like "*")} 
}

$APPS_SPS = getSPandAPP

$results = foreach($AADO in $APPS_SPS){
    $owner = getowner -objectid $AADO.objectid -objecttype $AADO.objecttype
    $AADO.PasswordCredentials | foreach{
    getcredentialdate -displayname $AADO.Displayname -objectid $AADO.objectid -objecttype $AADO.objecttype -credential $_ -credcount $AADO.PasswordCredentials.count `
        -allcreds $($AADO.PasswordCredentials.count -eq ($AADO.PasswordCredentials | where {$_.enddate -lt (get-date).DateTime}).count) `
        -owner $owner -replyurls $AADO.replyurls -homepage $AADO.homepage
    }
    $AADO.KeyCredentials | foreach{
    getcredentialdate -displayname $AADO.Displayname -objectid $AADO.objectid -objecttype $AADO.objecttype -credential $_ -credcount $AADO.KeyCredentials.count `
        -allcreds $($AADO.keyCredentials.count -eq ($AADO.keyCredentials | where {$_.enddate -lt (get-date).DateTime}).count) `
        -owner $owner -replyurls $AADO.replyurls -homepage $AADO.homepage
    }
}
$report = "$reportpath\aad_appsp_export_$(get-date -Format yyyyMMddHHmm).csv"
$results | export-csv $report -NoTypeInformation

$report = "$reportpath\aad_appsp_expired_w_owner_$(get-date -Format yyyyMMddHHmm).csv"
$results | where {$_.AllCredsExpired -eq $True -and $_.owner -ne $null} | sort displayname | select owner, displayname, objecttype, CountofCreds, replyurls -Unique | sort owner, displayname | export-csv $report -NoTypeInformation

$report = "$reportpath\aad_appsp_expired_credential_wo_owner_$(get-date -Format yyyyMMddHHmm).csv"
$results | where {$_.AllCredsExpired -eq $True -and $_.Expired -eq $True -and $_.owner -eq $null} | sort displayname | select displayname, objecttype, owner, replyurls -Unique | export-csv $report -NoTypeInformation



<#
$results | where {$_.PasswordCredentials.EndDate -gt (get-date).AddYears(2) -or $_.keycredentials.EndDate -gt (get-date).AddYears(2)} | select displayname, objecttype

$results | where {$_.PasswordCredentials.EndDate -gt (get-date).AddYears(2) -or $_.keycredentials.EndDate -gt (get-date).AddYears(2)} | select *

#>
