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

<img width="400" alt="image" src="https://github.com/user-attachments/assets/66cf89db-04eb-4bc5-b1ac-9acdbe88e825" />

## Phase 1 – Infrastructure Deployment

### Provisioning the environment
<img width="400" alt="image" src="https://github.com/user-attachments/assets/5749e4e6-d557-4e60-a2f3-05cfea2e7752" />
<img width="400" alt="image" src="https://github.com/user-attachments/assets/2fae9226-703b-4daa-9ae5-a83a310902ef" />


**Purpose:**
This is the Azure portal VM creation screen, where I'm provisioning a Windows Server 2025 Datacenter VM to host the Active Directory domain controller. The configuration reflects deliberate cost and security tradeoffs for a lab environment.

Availabilty Options: No infrastructure redundancy required - Cost Optimization 

Size: Standard_D2als_v7 - 2 vcpus, 4 GiB memory - Cost Optimization 

Public inbound ports: RDP (3389) - Security Optimization

---

### Creation of Azure Active Directory
<img width="400"  alt="image" src="https://github.com/user-attachments/assets/f5764a20-c0e8-408d-8164-fe7c3e5c62eb" />

**Purpose:**
I automated the domain controller promotion in two steps, mirroring how you'd do it manually through the "Add Roles and Features" wizard. First, `installing-AD.ps1` installs the `AD-Domain-Services` Windows feature with its management tools. Then `installing-DomainController.ps1` runs `Install-ADDSForest` to stand up a brand-new Active Directory forest rooted at `ezesalvatore.local`, with `-InstallDns:$true` so the same server also becomes the domain's DNS provider. Both scripts are in this repo under `powershellScripts/`

---

## Creating the Active Directory Domain structure

### **Server to a Domain Controller**

<img width="1267" height="430" alt="image" src="https://github.com/user-attachments/assets/bac33593-f5eb-478b-a80b-2fc99c6d4bf6" />

<img width="1085" height="236" alt="image" src="https://github.com/user-attachments/assets/e20e2a33-1367-43f6-a75e-31192e30b25f" />

**Purpose:** 

This command builds a brand-new Active Directory forest rooted at `lab.local` and promotes this server into its first Domain Controller.

With `-InstallDns:$true` set, the server also becomes the domain's DNS provide

Once promotion completes, this server:

- Hosts the AD database
- Enforces Group Policy for any machine that joins `lab.local`

The Safe Mode Administrator Password is a separate credential used only for Directory Services Restore Mode (DSRM) for disaster recovery

---

### **Build the Organizational Structure and Security Groups**

**Purpose:**

An Organizational Unit (OU) is a container inside Active Directory used to organize users, computers, and groups by department, location, or function. OUs exist mainly for management and policy targeting. You link a Group Policy Object (GPO) to an OU, and every user or computer inside that OU automatically inherits it. This is how role-based access gets applied at scale instead of configuring machines one by one.

Security groups serve a related but different purpose: controlling access to resources, like file shares, printers, or applications. A user's OU determines *which policies apply to them*; their group membership determines *what they're allowed to access*.

---

### **Create User Accounts**

<img width="886" height="1140" alt="image" src="https://github.com/user-attachments/assets/ee32436a-8bb4-4e9d-a2d8-e5f430af8de9" />

<img width="941" height="661" alt="image" src="https://github.com/user-attachments/assets/9aeafc81-e3dc-48e9-8efe-f0344588456c" />

**Purpose:** 

Creating the user with `New-ADUser` and placing it in an OU via `-Path` is what ties that account to Group Policy. GPOs are linked to OUs, not individual users — so the moment an account lands in `OU=IT`, it's automatically in scope for every policy linked there. No extra step needed; it just applies on the next Group Policy refresh or reboot.

Two parameters work together to make the account usable:

- `AccountPassword` sets the credential
- `Enabled $true` is required separately, since AD creates accounts disabled by default

---

### **Configure Group Policy**

<img width="1317" height="706" alt="image" src="https://github.com/user-attachments/assets/9718ed71-524d-4a8c-9fdc-5d23dfad55c0" />

<img width="1317" height="706" alt="image" src="https://github.com/user-attachments/assets/53329258-fe09-49ca-8b67-0c1105a82c2e" />

<img width="1317" height="706" alt="image" src="https://github.com/user-attachments/assets/c987611e-09d8-461f-9ceb-6d6f49d4f2be" />

**Purpose:**

Group Policy is how settings get enforced across every machine and user in the domain without touching each one individually. A Group Policy Object (GPO) is a collection of settings that applies automatically to everything inside the OU it's linked to: password complexity, screen lock timers, USB restrictions, software installation controls, and similar rules all get defined once and pushed out from there

---

### **Configuring Second Virtual Machine**

<img width="1181" height="218" alt="image" src="https://github.com/user-attachments/assets/7af04124-c00c-45ef-b434-508aea568817" />

<img width="1920" height="989" alt="image" src="https://github.com/user-attachments/assets/d0043370-a194-4735-be9d-970df962e626" />

<img width="943" height="663" alt="image" src="https://github.com/user-attachments/assets/67dca6fd-4dbe-4ceb-9475-b8e58d19b4a1" />

**Purpose:** A Domain Controller isn't meant to double as a general endpoint for testing user policy, so a second VM was needed to confirm a GPO reaches a real machine and user, not just that it's linked in AD.

`aliceVM` was deployed into the same VNet as the DC (`testVM`), enabling domain join. Since Azure VMs default to Azure DNS, which doesn't know `lab.local`, the VNet's DNS servers were set to Custom and pointed at the DC's private IP. The `nslookup lab.local` output confirmed this worked, resolving to the DC's address before domain join was even attempted.

After joining `aliceVM` to the domain, its computer object was moved on the DC into the correct OU so the linked GPO would actually apply to it. This sequence (DNS, domain join, then OU placement) mirrors how GPO scoping works in a real environment.

---

### Proof of GPO Application: Live RDP Session

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/cf9d580c-3d7a-46eb-a3fc-c64d79ec5896" />

<img width="1115" height="628" alt="image" src="https://github.com/user-attachments/assets/7fe8c681-a9e6-4e62-8efa-98f2aab4258a" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/8dfa04fa-3681-4422-8791-396d8e65c6a5" />

**Purpose:** This GPO grants the `IT_Admins` group RDP access to `aliceVM635` through the "Allow log on through Remote Desktop Services" user right, confirmed by group membership carrying into a fresh Kerberos ticket at logon.

The same GPO also applies "Interactive logon: Machine inactivity limit," set to lock the screen after 100 seconds of no activity. This is a separate security control from the RDP right itself. It forces the session to relock and require credentials again if the machine sits idle, so an authenticated session doesn't stay open indefinitely without action.

Together these show both halves of access control on this policy: who is allowed to remote in, and how idle sessions get automatically secured without needing manual intervention.

---

## Summary

This project demonstrates end-to-end IAM implementation on Azure: infrastructure provisioning, Active Directory forest and domain controller deployment, OU and security group design, automated account provisioning via PowerShell, GPO-based policy enforcement, and validation against a live client session. The environment reflects the same sequence of steps and design principles used in enterprise-scale identity and access management deployments.
