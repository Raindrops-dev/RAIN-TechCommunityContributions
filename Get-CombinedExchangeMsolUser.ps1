<#
.SYNOPSIS
    Script written to pull data from MSOL, Exchange Online and Exchange
.EXAMPLE
    ./Get-CombinedExchangeMsolUser.ps1 -ImportCSVPath "Path to the CSV containing the users whose data needs to be polled" -ExportCSVPath "Path to the CSV that will contain the finalized data"
.NOTES
    Author: Padure Sergio
    Company: Raindrops.dev
    Last Edit: 2022-09-04
    Version 0.1 Initial functional code
#>
#Requires -Modules Microsoft.Graph, ExchangeOnlineManagement 


[CmdletBinding()]
param (
    [Parameter()]
    [string]$ImportCSVPath = "$PSscriptroot\users.csv",
    [Parameter()]
    [string]$ExportCSVPath = "$PSScriptroot\export.csv"
)


#Clearing the Screen
Clear-Host

#Setting Error Action preference to Stop to ensure the code stops in case of error
$ErrorActionPreference = "Stop"

#Setting Verbose Preference to have the output of the Write-Verbose code. Can be removed when putting the script in production.
$VerbosePreference = "Continue"

#Connect to Microsoft Graph
try {
    $null = Get-MgOrganization -ErrorAction Stop
} 
catch {
    Write-Host "You're not connected to Graph Api, please connect"
    Connect-MgGraph -Scopes "Directory.ReadWrite.All"
}

#Connect to Exchange Online V2
#Connect & Login to ExchangeOnline (MFA) - https://www.reddit.com/r/PowerShell/comments/gupsze/how_can_i_check_if_a_connectexchangeonline_is/
$getsessions = Get-PSSession | Select-Object -Property State, Name
$isconnected = (@($getsessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
If ($isconnected -ne "True") {
    Connect-ExchangeOnline
}

#Importing the CSV with the users to process
$Userstoprocess = Import-Csv -Path $ImportCSVPath
$Userstoprocess

#Preparing splatted params for MgGraph
$MGGraphProperties = @(
    "Id",
    "DisplayName",
    "Mail",
    "UserPrincipalName",
    "UserType",
    "LicenseAssignmentStates",
    "LicenseDetails",
    "AssignedLicenses",
    "AccountEnabled",
    "GivenName",
    "Surname"
)

$FinalOutput = @()

foreach ($usertoprocess in $Userstoprocess) {
    $UserDisplayName = $usertoprocess.Displayname
    $UserArchiveID = $usertoprocess.ArchiveID
    $UserPrincipalName = $usertoprocess.UserPrincipalName
    $Graph = Get-MgUser -ConsistencyLevel eventual -UserId $UserPrincipalName -Property $MGGraphProperties
    $AssignedLicenses = $Graph.AssignedLicenses
    switch ($null -ne $AssignedLicenses) {
        $true {$IsLicensed = $true}
        $false {$IsLicensed = $false}
    }    
    $EXO = Get-EXOMailbox -Identity $UserPrincipalName
    $EX = Get-Mailbox -Identity $UserDisplayName
    $userdata = [PSCustomObject]@{
        'UserPrincipalName'           = $UserPrincipalName
        'IsLicensed'                  = $IsLicensed
        'BlockCredential'             = $Graph.AccountEnabled
        'FirstName'                   = $Graph.GivenName
        'LastName'                    = $Graph.Surname
        'ArchiveID'                   = $UserArchiveID
        'DisplayName'                 = $UserDisplayName
        'RecipientTypeDetails'        = $EXO.RecipientTypeDetails
        'Alias'                       = $EXO.Alias
        'ArchiveStatus'               = $EX.ArchiveStatus
        'ArchiveState'                = $EX.ArchiveState
        'ArchiveQuota'                = $EX.ArchiveQuota
        'ArchiveDatabase'             = $EX.ArchiveDatabase
        'ArchiveDatabaseGuid'         = $EX.ArchiveDatabaseGuid
        'AutoExpandingArchiveEnabled' = $EX.AutoExpandingArchiveEnabled
    }
    $FinalOutput += $userdata
}

$FinalOutput | Select-Object DisplayName, ArchiveID, UserPrincipalName, IsLicensed, BlockCredential, FirstName, LastName, RecipientTypeDetails, Alias, ArchiveStatus, ArchiveState, ArchiveQuota, ArchiveDatabase, ArchiveDatabaseGuid, AutoExpandingArchiveEnabled  | Export-Csv -NoTypeInformation $ExportCSVPath -Delimiter ',' -Encoding UTF8