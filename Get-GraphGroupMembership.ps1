<#
.SYNOPSIS
    Script written to get the Azure AD Group membership for a list of users through Graph API
.EXAMPLE
    ./Get-GraphGroupMembership.ps1 -UsersListPath "Path to the list of users" -ExportFileName "Filename of the export CSV file, with .csv extension" -ExportCSVPath "Path to where the CSV will be exported"
.NOTES
    Author: Padure Sergio
    Company: Raindrops.dev
    Last Edit: 2022-08-23
    Version 0.1 Initial functional code
    Original Script: Get-AzureADGroupMembership
    Mapping: https://docs.microsoft.com/en-us/powershell/microsoftgraph/azuread-msoline-cmdlet-map?view=graph-powershell-1.0
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

$ErrorActionPreference = "Stop"

#Connect to Graph API
try {
    $null = Get-MgOrganization -ErrorAction Stop
} 
catch {
    Write-Host "You're not connected to Graph Api, please connect"
    Connect-MgGraph -Scopes "Directory.ReadWrite.All"
}

#Get the list of those users whose group needs to be checked from the text file
$groupusers = Get-Content -Path $UsersListPath

#Preparing object for storing the results
$finaloutput = @()

#Looping through each user to get their group membership
foreach ($groupuser in $groupusers) {
    try {
        #Getting full information of the user account
        $AzureAdUser = Get-MgUser -UserId $groupuser
        #Getting group membership for the user
        $GroupMembership = Get-MgUserMemberOf -UserId $groupuser
        #Looping through all the groups the user is member of and adding the properties to the final output object
        foreach ($group in $GroupMembership) {
            $tempobject = @{
                UserPrincipalName    = $AzureAdUser.UserPrincipalName
                GroupTypes           = [string]$group.AdditionalProperties.groupTypes
                GroupDisplayname     = $group.AdditionalProperties.displayName
                GroupDescription     = $group.AdditionalProperties.description
                GroupMailEnabled     = $group.AdditionalProperties.mailEnabled
                GroupSecurityEnabled = $group.AdditionalProperties.securityEnabled
                GroupObjectId        = $group.Id
                ResultType           = $group.AdditionalProperties."`@odata.type"
            }
            #Adding temporary object to the final output object
            $finaloutput += New-Object -TypeName psobject -Property $tempobject
        }
    }
    catch {
        $_.Error[0]
    }

}

#Showing the results of the search
$finaloutput | Select-Object UserPrincipalName, ResultType, GroupTypes, GroupDisplayname, GroupSecurityEnabled, GroupMailEnabled, GroupObjectId | Sort-Object -Property UserPrincipalName, ResultType, GroupTypes, GroupDisplayname | Format-Table

#Outputting the result of the search to a CSV
$finaloutput | Select-Object UserPrincipalName, ResultType, GroupTypes, GroupDisplayname, GroupSecurityEnabled, GroupMailEnabled, GroupObjectId | Sort-Object -Property UserPrincipalName, ResultType, GroupTypes, GroupDisplayname | Export-Csv -Path "$ExportCSVPath\$ExportFileName" -NoTypeInformation -Encoding Unicode
