<# this code is a hack job but works perfectly

this will walk a conditional access policy settings and will export it into an object.  this should require no additional changes

#>
param($exportfile=".\conditional_access_policy_export.csv")

function resolveguid{
    param($in,$cast)
    #write-host $cast
    if($in -match "(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$"){
        try{(Get-AzureADObjectByObjectId -ObjectIds $in).displayname}catch{$in}
    }elseif(($in | get-member)[0].TypeName -eq "system.int32"){$results = @()
        $in -split " " | foreach{$results = 
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
            #"$space" + "$($_.name)"
            #($objcap).($_.name)   #comment this out
            #$hash_prop.add($("$space" + "/" + "$($_.name)"),$null)
            if("$space" + "/" + "$($_.name)" -eq "/GrantControls/BuiltInControls"){
            $hash_prop.add($("$space" + "/" + "$($_.name)"),$(($objcap).($_.name)))
            }
            expandcap -objcap ($objcap).($_.name) -space $("$space" + "/" + "$($_.name)") -cast ($objcap | get-member)[0].TypeName
        }
        
}
}
}

#Get-AzureADMSConditionalAccessPolicy -PolicyId 4998f8af-e8c5-4ab2-b598-c33e96e12ab8 -pv cap  | foreach{
$conditional_access_Policies = Get-AzureADMSConditionalAccessPolicy -pv cap  | foreach{
$hash_prop = @{}
write-host "Dumping $($cap.displayname)"
expandcap -objcap $cap -space $null

new-object psobject -property $hash_prop
} 

$unique_props = $conditional_access_Policies | foreach{$_ | get-member -MemberType NoteProperty} | select name -unique
$unique_props = @("/Id","/DisplayName","/State") + ($unique_props | where {$_.name -notin "/Id","/DisplayName","/State"} | sort name).name
$conditional_access_Policies | select $unique_props | export-csv $exportfile -NoTypeInformation
write-host "Results can be found here $exportfile"
