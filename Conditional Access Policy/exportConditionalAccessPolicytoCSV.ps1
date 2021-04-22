#Requires -modules AzureADPreview
<#
.VERSION 2021.4.22
.GUID 18bf582a-f85b-4a89-8f60-e52845ca1c08
.AUTHOR Chad.Cox@microsoft.com
    https://blogs.technet.microsoft.com/chadcox/ (retired)
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
.DESCRIPTION
This script is unique.  almost all code requires to know the mapping.  what makes this different is I crawl
the object and each properties sub object.  this way as conditional access policy change.  this will change along with it.

This code is a hack job but works perfectly.  I appologies for not using good variables or function names.

4/22 i have it using the location command to translate its guid
it was trying to enum the sign in frecuency I fixed that

#>
param($exportfile=".\conditional_access_policy_export_$(get-date -f yyyy-MM-dd-hh-mm-ss).csv")

try{Get-AzureADCurrentSessionInfo | out-host}catch{Connect-azuread}

function resolveguid{
    param($in,$cast)
    
    if($in -match "(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$" -and $cast -notlike "*location*"){$results = @()
        $in -split " " | foreach{
        $results += try{(Get-AzureADObjectByObjectId -ObjectIds $_).displayname}catch{$_}}
        if(!($results)){$results = $in -split " "}
        return $results
    }elseif($in -match "(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$" -and $cast -like "*location*"){$results = @()
        $in -split " " | foreach{
        $results += try{(Get-AzureADMSNamedLocationPolicy -PolicyId $_).displayname}catch{$_}}
        if(!($results)){$results = $in -split " "}
        return $results
    }elseif($cast -eq "Microsoft.Open.MSGraph.Model.ConditionalAccessSignInFrequency"){
        return $in
        
    }elseif(($in | get-member)[0].TypeName -eq "system.int32"){$results = @()
        $in -split " " | foreach{
        $results += invoke-expression "[$cast].GetEnumName([int]$_)"}
        if(!($results)){$results = $in -split " "}
        return $results
    }else{
        return $in
    }
}


function expandcap{
    param($objcap,$space,$cast)
    if($objcap){
        #($objcap | get-member)[0].TypeName
        if(($objcap | get-member)[0].TypeName -notlike "Microsoft.Open.MSGraph.Model.*"){
            if($space -eq "/Id"){$hash_prop.add($space,$objcap)}else{
            $hash_prop.add($($space -replace "/value__",""),$([string]$((resolveguid -in $objcap  -cast $cast) -join ";")))
            }
        }Else{
            $objcap | get-member -membertype Property | foreach{
            
                if("$space" + "/" + "$($_.name)" -eq "/GrantControls/BuiltInControls" -and $(($objcap).($_.name)) -eq "Block"){
            
                $hash_prop.add($("$space" + "/" + "$($_.name)"),$(($objcap).($_.name)))
                }
                expandcap -objcap ($objcap).($_.name) -space $("$space" + "/" + "$($_.name)") -cast ($objcap | get-member)[0].TypeName
            }
        
        }
    }
}

#Get-AzureADMSConditionalAccessPolicy -PolicyId 4998f8af-e8c5-4ab2-b598-c33e96e12ab8 -pv cap  | foreach{
$conditional_access_Policies = Get-AzureADMSConditionalAccessPolicy  -pv cap  | foreach{
    $hash_prop = @{}
    write-host "Dumping $($cap.displayname)"
    expandcap -objcap $cap -space $null
    new-object psobject -property $hash_prop
} 

#This is to make sure each object has common properties.
$unique_props = $conditional_access_Policies | foreach{$_ | get-member -MemberType NoteProperty} | select name -unique
$unique_props = @("/Id","/DisplayName","/State") + ($unique_props | where {$_.name -notin "/Id","/DisplayName","/State"} | sort name).name

$conditional_access_Policies | select $unique_props | export-csv $exportfile -NoTypeInformation
