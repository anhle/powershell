Add-Type -AssemblyName Microsoft.Office.Interop.Outlook

$olFolders = "Microsoft.Office.Interop.Outlook.OlDefaultFolders" -as [type]
$outlook = New-Object -ComObject Outlook.Application
$namespace = $outlook.GetNameSpace("MAPI")
$inbox = $namespace.getDefaultFolder($olFolders::olFolderInbox)
$folder = $inbox.Folders | where {$_.Name -eq "YourFolderName"}

$folder.Items | foreach {
  $_.SaveAs("C:\EMLFiles\" + $_.Subject + ".eml", 17)
}
