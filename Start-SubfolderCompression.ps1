<#
.SYNOPSIS
    Script written to compress subfolders of a given folder
.EXAMPLE
    ./Start-SubfolderCompression.ps1 -UncompressedFolder "Path to the folder containing the subfolders to compress" -CompressedOutputFolder "Path to the folder to which the compressed files will be saved"
.NOTES
    Author: Padure Sergio
    Company: Raindrops.dev
    Last Edit: 2022-09-03
    Version 0.1 Initial functional code
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$UncompressedFolder,
    [Parameter()]
    [string]$CompressedOutputFolder
)

#Clearing the Screen
Clear-Host

#Setting Error Action preference to Stop to ensure the code stops in case of error
$ErrorActionPreference = "Stop"

#Setting Verbose Preference to have the output of the Write-Verbose code
$VerbosePreference = "Continue"

try {
    #Checking if the provided values exist
    try {
        $null = Get-Item -Path $UncompressedFolder -ErrorAction Stop
        Write-Verbose "Folder whose subfolders will be Compressed: $UncompressedFolder"
    }
    catch {
        throw "Folder $UncompressedFolder doesn't exist"
    }
    try {
        $null = Get-Item -Path $CompressedOutputFolder -ErrorAction Stop
        Write-Verbose "Main folder in which the subfolder for the compressed archives will be created in: $CompressedOutputFolder "
    }
    catch {
        throw "Folder $CompressedOutputFolder doesn't exist"
    }
    
    #Getting the subfolders contained in the given folder
    $UncompressedSubFolders = Get-ChildItem -Path $UncompressedFolder | Select-Object -ExpandProperty "FullName"
    Write-Verbose "List of subfolders in the main provided folder: $UncompressedSubFolders"

    #Getting the Name of the main folder provided
    $UncompressedFolderName = Get-Item $UncompressedFolder | Select-Object -ExpandProperty 'Name'
    Write-Verbose "The Name of the main folder provided is $UncompressedFolderName"

    #Preparing variable of compressed outputs folder
    $CompressedOutputsSubfolder = "$CompressedOutputFolder\$UncompressedFolderName"
    Write-Verbose "Compressed Outputs SubFolder is $CompressedOutputsSubFolder"

    #Checking if the concerned folder exists in the Compressed folder and creating it if not
    $null = New-Item -Path $CompressedOutputsSubfolder -ItemType Directory -Force
    Write-Verbose "$CompressedOutputsSubfolder path creation done if not exists"

    #Starting the main loop of the compression pipeline
    foreach ($UncompressedSubFolder in $UncompressedSubFolders) {
        #Getting the subfolder name
        $SubFolderName = Get-Item $UncompressedSubFolder | Select-Object -ExpandProperty 'Name'
        $FinalZipPath = "$CompressedOutputsSubfolder\$SubFolderName.zip"
        $FinalZipPathExists = Test-Path -Path $FinalZipPath -PathType Leaf

        if ($FinalZipPathExists) {
            Write-Output "$FinalZipPath already exists, moving on"
        }
        else {
            Write-Verbose "The Subfolder Currently Being Compressed is $UncompressedSubFolder to $FinalZipPath"
            Compress-Archive -Path "$UncompressedSubFolder\*" -DestinationPath $FinalZipPath
            Write-Output "The Subfolder $UncompressedSubFolder has been compressed to $FinalZipPath"
        }        
    }

    Write-Output "No errors until now so everything should have been executed correctly"  
}
catch {
    $_
}