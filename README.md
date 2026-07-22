# Active Directory Lab: IAM on Azure

---
### Overview

Systems Administrator lab standing up centralized identity and access management for `ezesalvatore.local`.

**Work performed:**

- **AD DS Deployment:** Provisioned a Windows Server 2025 VM in Azure, promoted to domain controller, standing up the `ezesalvatore.local` forest with the DC also serving as DNS
- **OU Structure:** Designed OUs to separate policy targeting from resource access
- **RBAC:** Created security groups for resource access control
- **Automated Provisioning:** Scripted user creation with PowerShell (`New-ADUser`), scoped to OU via `-Path`
- **GPO Enforcement:** Linked GPOs for RDP logon rights and inactivity-based screen lock
- **Server Onboarding:** Joined `aliceVM635` to the domain, resolved DNS, moved computer object into correct OU
- **End-to-End Validation:** Verified via live RDP session — group-based access control and idle lockout confirmed working

---
### Project Architecture - Network Topology

<img width="500" alt="image" src="https://github.com/user-attachments/assets/66cf89db-04eb-4bc5-b1ac-9acdbe88e825" />

## Phase 1 – Infrastructure Deployment

### Provisioning the environment
<img width="500" alt="image" src="https://github.com/user-attachments/assets/5749e4e6-d557-4e60-a2f3-05cfea2e7752" />
<img width="500" alt="image" src="https://github.com/user-attachments/assets/2fae9226-703b-4daa-9ae5-a83a310902ef" />

**Purpose:**
This is the Azure portal VM creation screen, where I'm provisioning a Windows Server 2025 Datacenter VM to host the Active Directory domain controller. The configuration reflects deliberate cost and security tradeoffs for a lab environment.

**Availabilty Options:** No infrastructure redundancy required - Cost Optimization 

**Size:** Standard_D2als_v7 - 2 vcpus, 4 GiB memory - Cost Optimization 

**Public inbound ports:** RDP (3389) - Security Optimization

---

### Creation of Azure Active Directory
<img width="500" alt="image" src="https://github.com/user-attachments/assets/f5764a20-c0e8-408d-8164-fe7c3e5c62eb" />


**Purpose:**

📄 Script: [`installing-AD.ps1`](https://github.com/ezesalvatore/Azure-Active-Directory/blob/main/powershellScripts/installing-AD.ps1)

Rather than clicking through the "Add Roles and Features" GUI wizard, I automated the AD DS and Group Policy Management installation with PowerShell to be easy to re-run if the environment needs to be rebuilt. 

📄 Script: [`installing-GPMC.ps1`](https://github.com/ezesalvatore/Azure-Active-Directory/blob/main/powershellScripts/installing-GPMC.ps1)

GPMC isn't bundled with the AD DS install by default, it's a separate Windows feature, which is why it won't appear in Server Manager until this second script runs. `-IncludeManagementTools` on the first script pulls in the GUI snap-ins.

---

## Creating the Active Directory Domain structure

### **Server to a Domain Controller**

<img width="500" alt="image" src="https://github.com/user-attachments/assets/83f2b65c-bbb9-43e3-9a17-a2defd308e2b" />

📄 Script: [`installing-DomainController.ps1`](https://github.com/ezesalvatore/Azure-Active-Directory/blob/main/powershellScripts/installing-DomainController.ps1)

**Purpose:**
This command builds a brand-new Active Directory forest rooted at `ezesalvatore.local` and promotes this server into its first Domain Controller.

With `-InstallDns:$true` set, the server also becomes the domain's DNS provider — this is how clients locate domain services and find other domain controllers.

Once promotion completes, this server:
- Hosts the AD database
- Enforces Group Policy for any machine that joins `ezesalvatore.local`

The Safe Mode Administrator Password is a separate credential used only for Directory Services Restore Mode (DSRM), used for disaster recovery.

---

## **Phase 2 – Building Out the Domain**

### **Build the Organizational Structure and Security Groups**

**Purpose:**

📄 Script: [`create-organizationalUnit.ps1`](https://github.com/ezesalvatore/Azure-Active-Directory/blob/main/powershellScripts/create-organizationalUnit.ps1)

An Organizational Unit (OU) is a container inside Active Directory used to organize users, computers, and groups by department, location, or function. OUs exist mainly for management and policy targeting. You link a Group Policy Object (GPO) to an OU, and every user or computer inside that OU automatically inherits it. This is how role-based access gets applied at scale instead of configuring machines one by one.

📄 Script: [`create-securityGroup.ps1`](https://github.com/ezesalvatore/Azure-Active-Directory/blob/main/powershellScripts/create-securityGroup.ps1)

Security groups serve a related but different purpose: controlling access to resources, like file shares, printers, or applications. A user's OU determines *which policies apply to them*; their group membership determines *what they're allowed to access*.

---

### **Create User Accounts**

**Purpose:** 

📄 Script: [`create-users.ps1`](https://github.com/ezesalvatore/Azure-Active-Directory/blob/main/powershellScripts/create-users.ps1)

Creating the user with `New-ADUser` and placing it in an OU via `-Path` is what ties that account to Group Policy. GPOs are linked to OUs, not individual users, so the moment an account lands in `OU=IT`, it's automatically in scope for every policy linked there. No extra step is needed; it just applies on the next Group Policy refresh or reboot.

Two parameters work together to make the account usable:

- **`AccountPassword`**: sets the credential
- **`Enabled $true`**: required separately, since AD creates accounts disabled by default

---

### **Configure Group Policy**

<img width="500" alt="image" src="https://github.com/user-attachments/assets/38049b98-0983-4e9d-801e-670fbd267778" />

<img width="500" alt="image" src="https://github.com/user-attachments/assets/e4bde1a3-e545-4059-a9c6-c18c12e45aae" />

<img width="500" alt="image" src="https://github.com/user-attachments/assets/0b9e2215-b1b9-44b0-8562-27aa069d7602" />


**Purpose:**

Group Policy is how settings get enforced across every machine and user in the domain without touching each one individually. A Group Policy Object (GPO) is a collection of settings that applies automatically to everything inside the OU it's linked to: password complexity, screen lock timers, USB restrictions, software installation controls, and similar rules all get defined once and pushed out from there

---

### **Active Directory Logical Structure**

```
🌐 ezesalvatore.local (Domain)
│
├── 📁 OU: IT
│   ├── 👤 alice.chen
│   ├── 👥 Security Group: IT_Admins
│   └── 📜 GPO (linked here)
│       ├── 🖥️ RDP logon rights
│       └── 🔒 Inactivity lockout
│
├── 📁 OU: Finance
│   ├── 👤 bob.patel
│   └── 👥 Security Group: Finance_Users
│
├── 📁 OU: HR
│   ├── 👤 carol.jones
│   └── 👥 Security Group: HR_Users
│
├── 📁 OU: Sales
│   ├── 👤 david.smith
│   └── 👥 Security Group: Sales_Users
│
└── 📁 OU: Computers
    └── 🖥️ Dedicated container for workstation/server objects
```
---
## Phase 3 – Testing the Environment

### DNS Configuration & VNet Networking

<img width="500" alt="image" src="https://github.com/user-attachments/assets/37ebdad0-9941-423d-91ad-44a37f34d3d3" />

<img width="500" alt="image" src="https://github.com/user-attachments/assets/8eb476ac-0970-48b4-aa26-352bdc8267a6" />

**Purpose:**

To allow the computers to communicate with each other, I needed to make sure the network topology and DNS resolution were configured correctly.

1. Updated the virtual network's DNS settings, changing from Azure's default DNS to a custom setting pointing at the private IP of `ezesalvatoreVM` (`10.0.0.4`), the domain controller running AD DS. This ensures all VMs in the VNet resolve names through Active Directory instead of Azure's default DNS.
2. Created `aliceVM` to represent an IT admin's workstation and confirmed it was deployed in the same virtual network as `ezesalvatoreVM`. VMs must share a virtual network and use the domain controller as their DNS server to see each other and complete a domain join.
3. Ran `nslookup` from `aliceVM` and confirmed it could resolve `ezesalvatoreVM`, validating DNS was correctly pointed at AD before the domain join.

---

### Domain Join computer to ezesalvatore.local 

**Purpose:**

📄 Script: [`joining-domain.ps1`](https://github.com/ezesalvatore/Azure-Active-Directory/blob/main/powershellScripts/joining-domain.ps1)

The use of the joining-domain script will be used to help with the 


---

### Confirmation GPO Is Working: Live RDP Session
<img width="1110" height="607" alt="image" src="https://github.com/user-attachments/assets/12749749-0b7d-4a10-b216-187b53b6d432" />


**Purpose:**
This GPO grants the `IT_Admins` group RDP access to `aliceVM635` through the "Allow log on through Remote Desktop Services" user right, confirmed by group membership carrying into a fresh Kerberos ticket at logon. The same GPO also applies "Interactive logon: Machine inactivity limit," set to lock the screen after 100 seconds of no activity — a separate security control from the RDP right itself, forcing the session to relock and require credentials again if the machine sits idle. Together, these confirm both halves of access control on this policy: **who** is allowed to remote in, and **how** idle sessions get automatically secured without manual intervention.

---

## Summary

This project demonstrates end-to-end IAM implementation on Azure: infrastructure provisioning, Active Directory forest and domain controller deployment, OU and security group design, automated account provisioning via PowerShell, GPO-based policy enforcement, and validation against a live client session. The environment reflects the same sequence of steps and design principles used in enterprise-scale identity and access management deployments.
