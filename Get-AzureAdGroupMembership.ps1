#Script written by Padure Sergio (Raindrops.dev) for The Microsoft Tech Community

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

#Get the list of whose whose group needs to be checked from the text file
$groupusers = Get-Content -Path "C:\Temp\azureadusers.txt"

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
        $finaloutput += New-Object -TypeName psobject -Property $tempobject
    }
}

#Showing the results of the search
$finaloutput | Select-Object UserPrincipalName, GroupDisplayname, GroupSecurityEnabled, GroupMailEnabled, GroupObjectType, GroupObjectId | Sort-Object -Property UserPrincipalName, GroupObjectType, GroupDisplayname | Format-Table

#Outputting the result of the search to a CSV
$finaloutput | Select-Object UserPrincipalName, GroupDisplayname, GroupSecurityEnabled, GroupMailEnabled, GroupObjectType, GroupObjectId | Sort-Object -Property UserPrincipalName, GroupObjectType, GroupDisplayname | Export-Csv -Path "C:\temp\ResultantAzureAdGroups.csv" -NoTypeInformation -Encoding Unicode
