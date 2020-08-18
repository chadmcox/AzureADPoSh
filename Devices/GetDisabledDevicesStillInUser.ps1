#Requires -module azureadpreview
connect-azuread

#this will list devices that are still being used but are disabled
Get-AzureADAuditSignInLogs -filter "appDisplayName eq 'Microsoft Office' and status/errorCode eq 135011" -all $true | select `
    UserPrincipalName,AppDisplayName, @{Name="DeviceName";Expression={$_.DeviceDetail.DisplayName}}, `
    @{Name="ErrorCode";Expression={$_.Status.errorcode}}, @{Name="FailureReason";Expression={$_.Status.FailureReason}} -Unique | `
        export-csv .\aad_device_still_used_but_disabled.csv
