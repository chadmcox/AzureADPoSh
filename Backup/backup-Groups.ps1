#export Existing Azure AD Security Groups
get-azureadgroup -Filter "SecurityEnabled eq true" -All $true | `
    select ObjectId, DisplayName, DirSyncEnabled | `
        export-csv ".\Azure_AD_Security_Groups_$((Get-AzureADTenantDetail).DisplayName)_$(get-date -f yyyy-MM-dd).csv" -NoTypeInformation
