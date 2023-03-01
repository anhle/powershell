Add-Type -AssemblyName Microsoft.Office.Interop.Outlook

$olFolders = "Microsoft.Office.Interop.Outlook.OlDefaultFolders" -as [type]
$outlook = New-Object -ComObject Outlook.Application
$namespace = $outlook.GetNameSpace("MAPI")
$inbox = $namespace.getDefaultFolder($olFolders::olFolderInbox)
$folder = $inbox.Folders | where {$_.Name -eq "YourFolderName"}

$folder.Items | foreach {
  $_.SaveAs("C:\EMLFiles\" + $_.Subject + ".eml", 17)
}


Add-Type -AssemblyName Microsoft.Office.Interop.Outlook

$pstPath = "C:\Path\To\PST\File.pst"
$outputFolder = "C:\Path\To\Output\Folder"

$outlook = New-Object -ComObject Outlook.Application
$namespace = $outlook.GetNameSpace("MAPI")
$inbox = $namespace.OpenStore($pstPath).GetRootFolder()

$inbox.Items | foreach {
    $_.SaveAs(($outputFolder + "\" + $_.Subject + ".eml"), 17)
}
