# Active Directory Lab: IAM on Azure

---

Overview

Provisioned a Windows Server 2025 VM in Azure and promoted it to a domain controller, standing up a new Active Directory forest at `lab.local` with the DC also serving as DNS. Built out the OU structure and security groups, separating policy targeting (OUs) from resource access (groups), then automated user account creation with PowerShell (`New-ADUser`, scoped into the right OU via `-Path`). Configured and linked GPOs to enforce security controls like RDP logon rights and inactivity-based screen lock. Deployed a second VM (`aliceVM635`), fixed DNS resolution so it could find `lab.local`, joined it to the domain, and moved its computer object into the correct OU to bring it into policy scope. Verified the whole build end to end with a live RDP session, confirming group-based access control and automatic session lockout on idle, proof the GPOs were actually reaching a real machine and user, not just linked in AD.

---

### Provisioning the environment

<img width="867" height="892" alt="image" src="https://github.com/user-attachments/assets/2fd587b8-80cd-433c-a288-30bec554276e" />


**Purpose:** 

This is the Azure portal VM creation screen. I'm provisioning a Windows Server 2025 Datacenter VM in West US, this virtual machine is what I'll promote into my domain controller and build the rest of the Active Directory environment on top of.

---

### Creation of Azure Active Directory

!image.png

!image.png

!image.png

**Purpose:** 

I ran the PowerShell scripts to automate the process of creating the Active Directory domain and installed Group Policy without it, you will not see the Group Policy Management option in Server Manager

---

## Creating the Active Directory Domain structure

### **Server to a Domain Controller**

!image.png

!image.png

**Purpose:** 

This command builds a brand-new Active Directory forest rooted at `lab.local` and promotes this server into its first Domain Controller.

With `-InstallDns:$true` set, the server also becomes the domain's DNS provide

Once promotion completes, this server:

- Hosts the AD database
- Enforces Group Policy for any machine that joins `lab.local`

The Safe Mode Administrator Password is a separate credential used only for Directory Services Restore Mode (DSRM) for disaster recovery

---

### **Build the Organizational Structure and Security Groups**

!image.png

!image.png

!image.png

**Purpose:**

An Organizational Unit (OU) is a container inside Active Directory used to organize users, computers, and groups by department, location, or function. OUs exist mainly for management and policy targeting. You link a Group Policy Object (GPO) to an OU, and every user or computer inside that OU automatically inherits it. This is how role-based access gets applied at scale instead of configuring machines one by one.

Security groups serve a related but different purpose: controlling access to resources, like file shares, printers, or applications. A user's OU determines *which policies apply to them*; their group membership determines *what they're allowed to access*.

---

### **Create User Accounts**

!image.png

!image.png

**Purpose:** 

Creating the user with `New-ADUser` and placing it in an OU via `-Path` is what ties that account to Group Policy. GPOs are linked to OUs, not individual users — so the moment an account lands in `OU=IT`, it's automatically in scope for every policy linked there. No extra step needed; it just applies on the next Group Policy refresh or reboot.

Two parameters work together to make the account usable:

- `AccountPassword` sets the credential
- `Enabled $true` is required separately, since AD creates accounts disabled by default

---

### **Configure Group Policy**

!image.png

!image.png

!image.png

**Purpose:**

Group Policy is how settings get enforced across every machine and user in the domain without touching each one individually. A Group Policy Object (GPO) is a collection of settings that applies automatically to everything inside the OU it's linked to: password complexity, screen lock timers, USB restrictions, software installation controls, and similar rules all get defined once and pushed out from there

---

### **Configuring Second Virtual Machine**

!image.png

!image.png

!image.png

**Purpose:** A Domain Controller isn't meant to double as a general endpoint for testing user policy, so a second VM was needed to confirm a GPO reaches a real machine and user, not just that it's linked in AD.

`aliceVM` was deployed into the same VNet as the DC (`testVM`), enabling domain join. Since Azure VMs default to Azure DNS, which doesn't know `lab.local`, the VNet's DNS servers were set to Custom and pointed at the DC's private IP. The `nslookup lab.local` output confirmed this worked, resolving to the DC's address before domain join was even attempted.

After joining `aliceVM` to the domain, its computer object was moved on the DC into the correct OU so the linked GPO would actually apply to it. This sequence (DNS, domain join, then OU placement) mirrors how GPO scoping works in a real environment.

---

### Proof of GPO Application: Live RDP Session

!image.png

!image.png

!image.png

**Purpose:** This GPO grants the `IT_Admins` group RDP access to `aliceVM635` through the "Allow log on through Remote Desktop Services" user right, confirmed by group membership carrying into a fresh Kerberos ticket at logon.

The same GPO also applies "Interactive logon: Machine inactivity limit," set to lock the screen after 100 seconds of no activity. This is a separate security control from the RDP right itself. It forces the session to relock and require credentials again if the machine sits idle, so an authenticated session doesn't stay open indefinitely without action.

Together these show both halves of access control on this policy: who is allowed to remote in, and how idle sessions get automatically secured without needing manual intervention.

---

## Summary

This project demonstrates end-to-end IAM implementation on Azure: infrastructure provisioning, Active Directory forest and domain controller deployment, OU and security group design, automated account provisioning via PowerShell, GPO-based policy enforcement, and validation against a live client session. The environment reflects the same sequence of steps and design principles used in enterprise-scale identity and access management deployments.
