
<#PSScriptInfo

.VERSION 0.1

.GUID 476739f9-d907-4d5a-856e-71f9279955de

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

.TAGS Get-AzureRmContext Set-AzureRmContext Get-AzureRmRoleAssignment

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

#Requires -Module azurerm

<# 

.DESCRIPTION 
 Ensure that multi-factor authentication is enabled for all Azure Subscription privileged users 

#> 
Param()

function getAzureSubRBACRoles{
    read-host "Press enter, then login with Account  to query Azure Services"
    Connect-AzureRmAccount
    Get-AzureRmContext -ListAvailable -PipelineVariable AzureRMSub | Set-AzureRmContext | foreach{
        $subinfo = $AzureRMSub.name.split("-")
        write-Information "Gathering Infromation from $($AzureRMSub.id)"
        Get-AzureRmRoleDefinition -Custom -PipelineVariable ASUBRDEF | foreach{
            $ASUBRDEF.Actions | select `
                @{Name="SubscriptionID";Expression={$AzureRMSub.Subscription}},`
                @{Name="SubscriptionName";Expression={$subinfo[0]}},`
                @{Name="RoleName";Expression={$ASUBRDEF.Name}}, `
                @{Name="RoleID";Expression={$ASUBRDEF.ID}}, `
                @{Name="isCustom";Expression={$ASUBRDEF.isCustom}}, `
                @{Name="Action";Expression={$_}}, `
                @{Name="AssignableScopes";Expression={$ASUBRDEF.AssignableScopes}}
                @{Name="Result";Expression={if($ASUBRDEF.AssignableScopes -eq '/' -and
                    $ASUBRDEF.isCustom -eq $true -and $ASUBRDEF.isCustom -eq '*')
                    {"Review"}else{"Success"}}
        }
        Get-AzureRmRoleDefinition -PipelineVariable ASUBRDEF | foreach{
            $ASUBRDEF.Actions | select `
                @{Name="SubscriptionID";Expression={$AzureRMSub.Subscription}},`
                @{Name="SubscriptionName";Expression={$subinfo[0]}},`
                @{Name="RoleName";Expression={$ASUBRDEF.Name}}, `
                @{Name="RoleID";Expression={$ASUBRDEF.ID}}, `
                @{Name="isCustom";Expression={$ASUBRDEF.isCustom}}, `
                @{Name="Action";Expression={$_}}, `
                @{Name="AssignableScopes";Expression={$ASUBRDEF.AssignableScopes}}
                @{Name="Result";Expression={$ASUBRDEF.AssignableScopes}}
                @{Name="Result";Expression={if($ASUBRDEF.AssignableScopes -eq '/' -and
                    $ASUBRDEF.isCustom -eq $true -and $ASUBRDEF.isCustom -eq '*')
                    {"Review"}else{"Success"}}
        }
    }
}

getAzureSubRBACRoles