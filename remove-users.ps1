Import-Module ActiveDirectory

# Input file and log file variables
$csvFile = "C:\dev\userlist.csv"
$logFile = "C:\dev\UserRemovalLog.txt"

# Read CSV file
$users = Import-Csv $csvFile -Header "Username"

# Loop through each user and remove AD account
foreach ($user in $users) {
    $Username = $user.Username

    Write-Output "Deleting user account: $Username"

    if (Get-ADUser -F {SamAccountName -eq $Username}) {
        # Remove AD account
        Remove-ADUser -Identity $Username -Confirm:$False
        if (!$?) {
            Write-Error "Failed to remove user: $Username"
            $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to remove user: $Username"
            $msg | Out-File -FilePath $logfile -Append
        } else {
            Write-Output "The following user has been deleted: $Username"
            $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - The following user has been deleted: $Username"
            $msg | Out-File -FilePath $logfile -Append
        }
    } else {
        Write-Error "User not found: $Username"
    }
}

Write-Output "Process complete."
