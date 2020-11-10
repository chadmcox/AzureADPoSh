$now=(get-date).AddDays(730))

Get-AzureADServicePrincipal -Filter "serviceprincipaltype eq 'Application'" -All $true -PipelineVariable aadsp | `
    select -ExpandProperty PasswordCredentials | where {$_.enddate -gt $now} | select `
        @{N="ObjectID";E={($aadsp.objectid}}, @{N="DisplayName";E={$aadsp.Displayname}},@{N="Expires";E={$_.enddate}}
        
Get-AzureADApplication -All $true -PipelineVariable aadsp | `
    select -ExpandProperty PasswordCredentials | where {$_.enddate -gt $now} | select `
        @{N="ObjectID";E={($aadsp.objectid}}, @{N="DisplayName";E={$aadsp.Displayname}},@{N="Expires";E={$_.enddate}}
