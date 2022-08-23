<#
.SYNOPSIS
    Script written to get the Azure AD Group membership for a list of users
.EXAMPLE
    ./Get-AzureAdGroupMembership.ps1 -UsersListPath "Path to the list of users" -ExportFileName "Filename of the export CSV file, with .csv extension" -ExportCSVPath "Path to where the CSV will be exported"
.NOTES
    Author: Padure Sergio
    Last Edit: 2022-08-23
    Version 0.1 Initial functional code
    Versopm 0.2 Optimization and adaptation to standards
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$UsersListPath = "C:\Temp\azureadusers.txt",
    [Parameter()]
    [string]$ExportFileName = "ResultantAzureAdGroups.csv",
    [Parameter()]
    [string]$ExportCSVPath = "C:\temp"
)

#Clearing the Screen
Clear-Host

#Connect to Azure AD
try {
    $null = Get-AzureADTenantDetail
} 
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] {
    Write-Host "You're not connected to Azure Ad, please connect"
    Connect-AzureAD
}

#Get the list of those users whose group needs to be checked from the text file
$groupusers = Get-Content -Path $UsersListPath

#Preparing object for storing the results
$finaloutput = @()

#Looping through each user to get their group membership
foreach ($groupuser in $groupusers) {
    #Getting full information of the user account
    $AzureAdUser = Get-AzureADUser -ObjectId $groupuser
    #Getting group membership for the user
    $GroupMembership = Get-AzureADUserMembership -ObjectId $AzureAdUser.ObjectId
    #Looping through all the groups the user is member of and adding the properties to the final output object
    foreach ($group in $GroupMembership) {
        $tempobject = @{
            UserPrincipalName    = $AzureAdUser.UserPrincipalName
            GroupDisplayname     = $group.DisplayName
            GroupObjectType      = $group.ObjectType
            GroupMailEnabled     = $group.MailEnabled
            GroupSecurityEnabled = $group.SecurityEnabled
            GroupObjectId        = $group.ObjectId
        }
        #Adding temporary object to the final output object
        $finaloutput += New-Object -TypeName psobject -Property $tempobject
    }
}

#Showing the results of the search
$finaloutput | Select-Object UserPrincipalName, GroupDisplayname, GroupSecurityEnabled, GroupMailEnabled, GroupObjectType, GroupObjectId | Sort-Object -Property UserPrincipalName, GroupObjectType, GroupDisplayname | Format-Table

#Outputting the result of the search to a CSV
$finaloutput | Select-Object UserPrincipalName, GroupDisplayname, GroupSecurityEnabled, GroupMailEnabled, GroupObjectType, GroupObjectId | Sort-Object -Property UserPrincipalName, GroupObjectType, GroupDisplayname | Export-Csv -Path "$ExportCSVPath\$ExportFileName" -NoTypeInformation -Encoding Unicode
