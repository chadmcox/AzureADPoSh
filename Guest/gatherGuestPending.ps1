Get-AzureADUser -Filter "UserState eq 'PendingAcceptance'" -All $true | `
  select objectid, userprincipalname, Mail,CreationType, UserState, UserStateChangedOn | export-csv .\guest_pending.csv -NoTypeInformation
