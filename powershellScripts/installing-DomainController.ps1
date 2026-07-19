# Promote this server to a Domain Controller by standing up a brand-new
# Active Directory forest. This is the PowerShell equivalent of running
# the "Add Roles and Features" wizard and selecting AD DS promotion.

Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName 'ezesalvatore.local' `        # New forest root domain
    -DomainNetBiosName 'LAB' `                # Legacy NetBIOS name 
    -InstallDns:$true `                       # Install & configure DNS on this DC
    -SafeModeAdministratorPassword (ConvertTo-SecureString 'testadmin123!' -AsPlainText -Force) `  # DSRM recovery password
    -Force:$true                              # Suppress confirmation prompts

# Server will reboot automatically once promotion completes.
