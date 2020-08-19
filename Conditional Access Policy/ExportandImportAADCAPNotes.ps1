<#
I know this works with azureadpreview 2.0.2.105
when trying to convert the entire policy to a json I had problems with the null values and multi string value properties converting correctly.
I was able to move past this by splitting out conditions, grantcontrols, and sessioncontrols into their own json.  they convert correctly that way.
#>

#Export all conditional access policies into a files, each policy will create 4 files.
Get-AzureADMSConditionalAccessPolicy -pv policy | foreach{
    $policy.Conditions | ConvertTo-Json -compress | out-file ".\$($policy.displayname)_conditions.json"
    $policy.GrantControls | ConvertTo-Json -compress | out-file ".\$($policy.displayname)_GrantControls.json"
    $policy.SessionControls | ConvertTo-Json -compress | out-file ".\$($policy.displayname)_SessionControls.json"
    $policy | ConvertTo-Json -compress -Depth 1 | out-file ".\$($policy.displayname)_base.json"
}

#This will restore all the conditional access policies.
get-childitem .\*_base.json | foreach{
    $cap = Get-Content $_.FullName | -Raw | ConvertFrom-Json
    New-AzureADMSApplicationKey -displayname $cap.displayname
        -Conditions (Get-Content '.\$($cap.displayname)_conditions.json' -Raw | ConvertFrom-Json) `
        -GrantControls (Get-Content '.\$($cap.displayname)_GrantControls.json' -Raw | ConvertFrom-Json) `
        -SessionControls (Get-Content '.\$($cap.displayname)_SessionControls.json' -Raw | ConvertFrom-Json) `
        -state $cap.state
}
