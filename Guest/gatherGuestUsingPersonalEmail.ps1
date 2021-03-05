Get-AzureADUser -Filter "userType eq 'Guest'" -all $true -PipelineVariable guest | `
    where {$_.UserPrincipalName -match "gmail.com|hotmail.com|msn.com|ymail.com|aol.com|msn.com|outlook.com|live.com|googlemail.com|yahoo.com"} | `
        select objectid, userprincipalname, Mail,CreationType, UserState, UserStateChangedOn   | export-csv .\guest_personal_email.csv
