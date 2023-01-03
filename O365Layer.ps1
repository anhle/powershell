Param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile,
    [int]$ManualThrottle=0,
    [double]$ActiveThrottle=.25,
    [int]$ResetSeconds=870,
    [string]$IdentifyingProperty
)

# Writes output to a log file with a time date stamp
Function Write-Log {
    Param ([string]$string)
    
    # Get the current date
    [string]$date = Get-Date -Format G
        
    # Write everything to our log file
    ( "[" + $date + "] - " + $string) | Out-File -FilePath $LogFile -Append
    
}

# Sleeps X seconds and displays a progress bar
Function Start-SleepWithProgress {
    Param([int]$sleeptime)

    # Loop Number of seconds you want to sleep
    For ($i=0;$i -le $sleeptime;$i++){
        $timeleft = ($sleeptime - $i);
        
        # Progress bar showing progress of the sleep
        Write-Progress -Activity "Sleeping" -CurrentOperation "$Timeleft More Seconds" -PercentComplete (($i/$sleeptime)*100) -Status " "
        
        # Sleep 1 second
        start-sleep 1
    }
    
    Write-Progress -Completed -Activity "Sleeping" -Status " "
}


# Setup a new O365 Powershell Session
Function New-CleanO365Session {

    Write-Log "Removing all PS Sessions"

    # Destroy any outstanding PS Session
    Get-PSSession | Remove-PSSession -Confirm:$false
    
    # Force Garbage collection just to try and keep things more agressively cleaned up due to some issue with large memory footprints
    #[System.GC]::Collect()
    
    # Sleep 15s to allow the sessions to tear down fully
    Write-Log ("Sleeping 5 seconds for Session Tear Down")
    Start-SleepWithProgress -SleepTime 5

    # Clear out all errors
    $Error.Clear()
    
    # Create the session
    Write-Log "Creating new PS Session"
    
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Credential -Authentication Basic -AllowRedirection
        
    # Check for an error while creating the session
    if ($Error.Count -gt 0){
    
        Write-Log "[ERROR] - Error while setting up session"
        Write-log $Error
        
        # Increment our error count so we abort after so many attempts to set up the session
        $ErrorCount++
        
        # if we have failed to setup the session > 3 times then we need to abort because we are in a failure state
        if ($ErrorCount -gt 3){
        
            Write-log "[ERROR] - Failed to setup session after multiple tries"
            Write-log "[ERROR] - Aborting Script"
            exit
        
        }
        
        # If we are not aborting then sleep 60s in the hope that the issue is transient
        Write-Log "Sleeping 30s so that issue can potentially be resolved"
        Start-SleepWithProgress -sleeptime 30
        
        # Attempt to set up the sesion again
        New-CleanO365Session
    }
    
    # If the session setup worked then we need to set $errorcount to 0
    else {
        $ErrorCount = 0
    }
    
    # Import the PS session
    $null = Import-PSSession $session -AllowClobber
    
    # Set the Start time for the current session
    Set-Variable -Scope script -Name SessionStartTime -Value (Get-Date)
}

# Verifies that the connection is healthy
# Goes ahead and resets it every $ResetSeconds number of seconds either way
Function Test-O365Session {
    
    # Get the time that we are working on this object to use later in testing
    $ObjectTime = Get-Date
    
    # Reset and regather our session information
    $SessionInfo = $null
    $SessionInfo = Get-PSSession
    
    # Make sure we found a session
    if ($SessionInfo -eq $null) { 
        Write-Log "[ERROR] - No Session Found"
        Write-log "Recreating Session"
        New-CleanO365Session
    }    
    # Make sure it is in an opened state if not log and recreate
    elseif ($SessionInfo.State -ne "Opened"){
        Write-Log "[ERROR] - Session not in Open State"
        Write-log ($SessionInfo | fl | Out-String )
        Write-log "Recreating Session"
        New-CleanO365Session
    }
    # If we have looped thru objects for an amount of time gt our reset seconds then tear the session down and recreate it
    elseif (($ObjectTime - $SessionStartTime).totalseconds -gt $ResetSeconds){
        Write-Log ("Session Has been active for greater than " + $ResetSeconds + " seconds" )
        Write-Log "Rebuilding Connection"
        
        # Estimate the throttle delay needed since the last session rebuild
        # Amount of time the session was allowed to run * our activethrottle value
        # Divide by 2 to account for network time, script delays, and a fudge factor
        # Subtract 15s from the results for the amount of time that we spend setting up the session anyway
        [int]$DelayinSeconds = ((($ResetSeconds * $ActiveThrottle) / 2) - 15)
        
        # If the delay is >15s then sleep that amount for throttle to recover
        if ($DelayinSeconds -gt 0){
        
            Write-Log ("Sleeping " + $DelayinSeconds + " addtional seconds to allow throttle recovery")
            Start-SleepWithProgress -SleepTime $DelayinSeconds
        }
        # If the delay is <15s then the sleep already built into New-CleanO365Session should take care of it
        else {
            Write-Log ("Active Delay calculated to be " + ($DelayinSeconds + 15) + " seconds no addtional delay needed")
        }
                
        # new O365 session and reset our object processed count
        New-CleanO365Session
    }
    else {
        # If session is active and it hasn't been open too long then do nothing and keep going
    }
    
    # If we have a manual throttle value then sleep for that many milliseconds
    if ($ManualThrottle -gt 0){
        Write-log ("Sleeping " + $ManualThrottle + " milliseconds")
        Start-Sleep -Milliseconds $ManualThrottle
    }
}
$Credential = get-Credential
New-CleanO365Session