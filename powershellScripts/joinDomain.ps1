#Adding the computer into ezesalvatore.local domain

Add-Computer -DomainName "ezesalvatore.local" `
  -Credential (Get-Credential) `
  -Restart -Force
