Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue


#Function to replace all permission levels granted with "Read"
Function Reset-Permissions([Microsoft.SharePoint.SPSecurableObject]$Object)
{
    #Add Read Permission to Role Assignment, if not added already
    ForEach ($RoleAssignment in $Object.RoleAssignments)
    {
        $RoleDefinitionBindings = $RoleAssignment.RoleDefinitionBindings
        If(!($RoleDefinitionBindings.Contains($ReadPermission) -or $RoleDefinitionBindings.Contains($ViewOnlyPermission) -or $RoleDefinitionBindings.Contains($LimitedAccessPermission)))
        {
            $RoleAssignment.RoleDefinitionBindings.Add($ReadPermission)
            $RoleAssignment.Update()
            Write-host "`tAdded Read Permission to '$($RoleAssignment.Member.Name)'" -ForegroundColor Green
        }
    }
 
    #Remove All permissions other than Read or Similar
    ForEach ($RoleAssignment in $Object.RoleAssignments)
    {
        $RoleDefinitionBindings = $RoleAssignment.RoleDefinitionBindings
        For($i=$RoleAssignment.RoleDefinitionBindings.Count-1; $i -ge 0; $i--)
        {
            $RoleDefBinding = $RoleAssignment.RoleDefinitionBindings[$i]
            If( ($RoleDefBinding.Name -eq "Read") -or ($RoleDefBinding.Name -eq "View Only") -or ($RoleDefBinding.Name -eq "Limited Access") )
            {
                Continue;
            }
            Else
            {
                $RoleAssignment.RoleDefinitionBindings.Remove($RoleAssignment.RoleDefinitionBindings[$i])
                $RoleAssignment.Update()
                Write-host "`tRemoved '$($RoleDefBinding.Name)' Permission from '$($RoleAssignment.Member.Name)'" -ForegroundColor Yellow
            }
        }
    }
}
 





Import-Csv "C:\Temp\pstest\test.csv" | ForEach-Object {




    Write-Host "Procesing $($_.URL)"

    #insert the script here
    #Parameters
$SubsiteURL = $_.URL
 
#Get the Subsite
$Web = Get-SPWeb $SubsiteURL
 
#Break Permission Inheritance of the subsite, if not already
If(!$Web.HasUniqueRoleAssignments)
{
    $Web.BreakRoleInheritance($true)
}
 
#Get Required Permission Levels
$ReadPermission = $web.RoleDefinitions["Read"]
$ViewOnlyPermission = $web.RoleDefinitions["View Only"]
$LimitedAccessPermission = $web.RoleDefinitions["Limited Access"]
 
#Call the function to Reset Web permissions
Write-host "Resetting Permissions on Web..."-NoNewline
Reset-Permissions $Web
Write-host "Done!" -f Green
 
#Array to Skip System Lists and Libraries
$SystemLists =@("Converted Forms", "Master Page Gallery", "Customized Reports", "Form Templates", "List Template Gallery", "Theme Gallery",
           "Reporting Templates", "Solution Gallery", "Style Library", "Web Part Gallery","Site Assets", "wfpub")
   
#Loop through each list in the web
Foreach ($List in $Web.Lists)
{
    #Get only lists with unique permissions & Exclude Hidden System libraries
    If (($List.Hidden -eq $false) -and ($SystemLists -notcontains $List.Title) -and ($List.HasUniqueRoleAssignments) )
    {
        #Call the function to Reset List permissions
        Write-host -NoNewline "Resetting Permissions on List '$($List.title)'..."
        Reset-Permissions $List
        Write-host "Done!" -f Green
    }
}
 
#Check List items with unique permissions
Foreach ($List in $Web.Lists)
{
    #Get only lists with unique permissions & Exclude Hidden System libraries
    If (($List.Hidden -eq $false) -and ($SystemLists -notcontains $List.Title))
    {
        #Get All list items with unique permissions
        $UniqueItems = $List.GetItemsWithUniquePermissions()
        If($UniqueItems.count -gt 0)
        {
            #Call the function to Reset List Item permissions
            Write-host "Resetting Permissions on List Items of '$($List.title)'"
            $UniqueItems | ForEach-Object {
                Reset-Permissions $List.GetItemById($_.ID)
            }           
        }
    }
}

   #end insert

}
