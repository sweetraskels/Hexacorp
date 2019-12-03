Add-PSSnapin microsoft.sharepoint.powershell -ea Continue
$scriptDir =get-location

$farm=[Microsoft.SharePoint.Administration.SPFarm]::Local
foreach ($solution in $farm.Solutions) 
        {
            if ($solution.Deployed){
               Write-Host($solution.DisplayName)
               $solution.DisplayName >> "$scriptDir\Solutions.txt"
            }          
}
