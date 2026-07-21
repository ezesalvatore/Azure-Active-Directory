# Create the top-level Organizational Units (OUs) for ezesalvatore.local.
# Each OU acts as a container — departments get their own OU so
# users, computers, and groups can be managed and targeted by GPO separately.
New-ADOrganizationalUnit -Name "IT"        -Path "DC=ezesalvatore,DC=local"   # IT dept objects
New-ADOrganizationalUnit -Name "Finance"   -Path "DC=ezesalvatore,DC=local"   # Finance dept objects
New-ADOrganizationalUnit -Name "HR"        -Path "DC=ezesalvatore,DC=local"   # HR dept objects
New-ADOrganizationalUnit -Name "Sales"     -Path "DC=ezesalvatore,DC=local"   # Sales dept objects
New-ADOrganizationalUnit -Name "Computers" -Path "DC=ezesalvatore,DC=local"   # Dedicated OU for workstations/servers
