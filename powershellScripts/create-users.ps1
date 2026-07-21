# Shared temp password for all new accounts
$password = ConvertTo-SecureString "Welcome@2026!" -AsPlainText -Force

# Create users, one per department
New-ADUser -Name "alice.chen" -GivenName "Alice" -Surname "Chen" `
    -SamAccountName "alice.chen" -UserPrincipalName "alice.chen@ezesalvatore.local" `
    -Path "OU=IT,DC=ezesalvatore,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "bob.patel" -GivenName "Bob" -Surname "Patel" `
    -SamAccountName "bob.patel" -UserPrincipalName "bob.patel@ezesalvatore.local" `
    -Path "OU=Finance,DC=ezesalvatore,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "carol.jones" -GivenName "Carol" -Surname "Jones" `
    -SamAccountName "carol.jones" -UserPrincipalName "carol.jones@ezesalvatore.local" `
    -Path "OU=HR,DC=ezesalvatore,DC=local" -AccountPassword $password -Enabled $true

New-ADUser -Name "david.smith" -GivenName "David" -Surname "Smith" `
    -SamAccountName "david.smith" -UserPrincipalName "david.smith@ezesalvatore.local" `
    -Path "OU=Sales,DC=ezesalvatore,DC=local" -AccountPassword $password -Enabled $true

# Add each user to their department group
Add-ADGroupMember -Identity "IT_Admins"     -Members "alice.chen"
Add-ADGroupMember -Identity "Finance_Users" -Members "bob.patel"
Add-ADGroupMember -Identity "HR_Users"      -Members "carol.jones"
Add-ADGroupMember -Identity "Sales_Users"   -Members "david.smith"
