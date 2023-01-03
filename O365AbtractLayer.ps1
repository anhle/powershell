
#module has been designed to help troubleshooting on Office 365 services.


#region Common Script Blocks
<# Example to use/call this function
        write-log -Function "Function Missing-Mailbox" -Step "Get_CASMailbox" -Description "Mailbox not found"
        write-log -Function "Function Missing-Mailbox" -Step "Get_CASMailbox" -Description $error[0]
#>  
$LogFile = "/Users/diemdao/Desktop/Anh/projects/powershell/out.txt"
function Write-Log {   
    param ($function, $step, $Description)
    
    $tserror = Get-Date -Format yyyyMMdd_hhmmss
    $currentRecord = "$tserror,$function,$step,$Description"
    Out-File -FilePath $LogFile -InputObject $currentRecord -Encoding UTF8 -Append 
}
# Writes output to a log file with a time date stamp
Function Write-Log-Info {
    Param ([string]$string)
    
    # Get the current date
    [string]$date = Get-Date -Format G
        
    # Write everything to our log file
    ( "[" + $date + "] - " + $string) | Out-File -FilePath $LogFile -Append
}

function Disconnect-All {
    
    $CurrentDescription = "Disconnect is successful!"

    try {
        # Disconnect EXOv2
        if (("ExchangeOnlineManagement" -in (Get-Module).name)) {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        }

        # Disconnect all PsSessions
        Get-PSSession | Remove-PSSession
    }
    catch {
             
        $CurrentDescription = "`"" + $Global:Error[0].Exception.Message + "`"" 

    }

    write-log -Function "Disconnect - close sessions" -Step $CurrentProperty -Description $CurrentDescription

}
# Getting Credentials script block 
$Global:UserCredential = {
    Write-Host "`nPlease enter Office 365 Global Admin credentials:" -ForegroundColor Cyan
    $Global:O365Cred = Get-Credential
}

# Credential Validation block
$Global:CredentialValidation = { 
    If (!([string]::IsNullOrEmpty($errordescr)) -and !([string]::IsNullOrEmpty($global:error[0]))) {
        Write-Host "`nYou are NOT connected succesfully to $Global:banner. Please verify your credentials." -ForegroundColor Yellow
        $CurrentDescription = "`"" + $CurrentError + "`""
        write-log -Function "Connect-O365PS" -Step $CurrentProperty -Description $CurrentDescription
        #&$Global:UserCredential
    }
}

# Displaying connection status
$Global:DisplayConnect = {
    If ($errordescr -ne $null) {
        Write-Host "`nYou are NOT connected succesfully to $Global:banner" -ForegroundColor Red
        write-log -Function "Connect-O365" -Step $CurrentProperty -Description "You are NOT connected succesfully to $Global:banner"
        Write-Host "`nThe script will now exit." -ForegroundColor Red
        Read-Host
        exit
    }
    else {
        Write-Host "`nYou are connected succesfully to $Global:banner" -ForegroundColor Green
        write-log -Function "Connect-O365PS" -Step $CurrentProperty -Description "You are connected succesfully to $Global:banner"
    }
}
 # Function to connecto to O365 services
Function Connect-O365 {

    $Try = 0
    $global:errordesc = $null
    $Global:O365Cred = $null

    # Connecto to EXO Basic Authentication 
    If ($null -eq $Global:O365Cred) {
        &$Global:UserCredential
    }
    try {

        $Global:EXOSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $global:O365Cred -Authentication "Basic" -AllowRedirection -SessionOption $PSsettings -ErrorVariable errordescr -ErrorAction Stop 
        $CurrentError = $errordescr.exception  
        Import-Module (Import-PSSession $EXOSession  -AllowClobber -DisableNameChecking) -Global -DisableNameChecking -ErrorAction SilentlyContinue
        $CurrentDescription = "Success"
        
    }
    catch {
        $CurrentDescription = "`"" + $CurrentError.ErrorRecord.Exception + "`""
    } 
    &$Global:DisplayConnect
}


    
Function    Test-O365AbtractLayer {
    $CurrentProperty = "Connecting to ..."
    $CurrentDescription = "Success"
    Connect-O365


    
    #write-log -Function "Connecting to O365 " -Step $CurrentProperty -Description $CurrentDescription 
        
   
}
#Test-O365AbtractLayer
Connect-O365