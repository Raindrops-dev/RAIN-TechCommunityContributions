<#
.SYNOPSIS
    Script written to compress subfolders of a given folder
.EXAMPLE
    ./Start-AzCopyBackup.ps1 -InputCSV "Path to the CSV file containing the folder names to upload" -MainFolder "Path to the folder that contains the subfolders to upload" -BlobSasUrl "URL with the SAS key for the storage blob"
.NOTES
    Author: Padure Sergio
    Company: Raindrops.dev
    Last Edit: 2022-09-03
    Version 0.1 Initial functional code
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$InputCSV,
    [Parameter()]
    [string]$MainFolder,
    [Parameter()]
    [string]$BlobSasUrl
)

#Clearing the Screen
Clear-Host

#Setting Error Action preference to Stop to ensure the code stops in case of error
$ErrorActionPreference = "Stop"

#Setting Verbose Preference to have the output of the Write-Verbose code
$VerbosePreference = "Continue"

$RootDir = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)

#Starting logging
$dateandtime = Get-Date -Format "dd_MM_yyyy_HH-mm"
$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null
#Continuing
$ErrorActionPreference = "Continue"
Start-Transcript -path "$RootDir\AzCopy-$dateandtime.log" -append
$ProgressPreference = 'SilentlyContinue' 

#Checking if azcopy is present in the folder
#Automated downloading can be implemented with https://wmatthyssen.com/2021/03/03/powershell-azcopy-windows-64-bit-download-and-silent-installation/
if (Test-Path -Path "$PSScriptRoot\azcopy.exe") {
    Write-Output "AzCopy is in the folder of the script, continuing"
}
else {
    throw "AzCopy is not in the folder. Please download and copy to the folder where the script is."
}

#Importing the CSV
$UsersToCopy = Import-Csv -Path $InputCSV 

#Looping each Displayname
foreach ($UserToCopy in $UsersToCopy) {
    try {
        #Renaming DisplayName to ensure match with the folder name
        $SubFolderName = $UserToCopy.UserDisplayName -replace " ", "."
        Write-Verbose "Folder to copy is $SubFolderName"
        #Checking if the folder actually exists
        if (Test-Path -Path "$MainFolder\$SubFolderName") {
            Write-Output "$MainFolder\$SubFolderName exists. Continuing"
        }
        else {
            Write-Warning "$MainFolder\$SubFolderName doesn't exist. Moving on to next user"
        }
        .\azcopy.exe copy "$MainFolder\$SubFolderName" $BlobSasUrl --recursive=true
    }
    catch {
        $_
    }
}




#Stop logging
Stop-Transcript
