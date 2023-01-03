#Connect to Exchange Server
Function ConnectTo-Exchange () {
        try{

            #If want to save creds without having to enter password into Get-Credential every time
            $password = "S..." | ConvertTo-SecureString -asPlainText -Force
            $username = "..." 
            $creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)

            # $creds = New-Object System.Management.Automation.PSCredential($username,$password)

            #$ExchServerFQDN = "$env:computername.$env:userdnsdomain"
            #Sample:
            #$UserCredential = Get-Credential
	        #$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
	        #Import-PSSession $Session"
            Import-Module ExchangeOnlineManagement   
            Connect-ExchangeOnline -Credential $creds

            $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection 
            Import-PSSession $session -AllowClobber -DisableNameChecking
        }
        catch{
            throw "Unable to establish a session with the Exchange Server"
            exit
        }

}
ConnectTo-Exchange