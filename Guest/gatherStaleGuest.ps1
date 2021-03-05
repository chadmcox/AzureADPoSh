#looks for logon over the last 30 days

Get-AzureADUser -Filter "userType eq 'Guest'" -All $true | where {$_.userstate -ne 'PendingAcceptance'} | `
    where {!(Get-AzureADAuditSignInLogs -Filter "userid eq '$($_.objectid)'" -top 1 -ErrorAction SilentlyContinue)} | 
        select objectid, userprincipalname, Mail,CreationType, UserState, UserStateChangedOn | `
            export-csv .\guest_no30daylogon.csv -NoTypeInformation
