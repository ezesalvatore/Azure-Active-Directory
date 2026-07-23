#Adding computer to IT organizational unit

Get-ADComputer -Identity "aliceVM" | Move-ADObject -TargetPath "OU=IT,DC=ezesalvatore,DC=local"
