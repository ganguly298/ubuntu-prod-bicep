# Azure VM Bicep Deployment

Deploys an Ubuntu 24.04 LTS Virtual Machine (`Standard_B2s_v2`) into an **existing** Virtual Network and Subnet using Azure Bicep.

---

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in
  ```bash
  az login
  az account set --subscription <your-subscription-id>
  ```
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) (comes bundled with Azure CLI 2.20+)
- An existing **Azure Resource Group** (e.g. `jenkins-rg`)
- An existing **Virtual Network** and **Subnet** in that resource group

---

## Existing VNet & Subnet Requirement

This deployment does **not** create a new VNet. You must have an existing VNet and Subnet. Update the values in `production/parameters/vm.bicepparam` to match your environment:

```bicep
param existingVnetName   = 'JENKINS-VNET'   // your VNet name
param existingSubnetName = 'default'         // your Subnet name
```

The `vnet.bicep` module looks up the subnet ID from the existing resources at deploy time.

---

## File Structure

```
bicep-test/
├── README.md
└── production/
    ├── main.bicep                    # Entry point — wires modules together
    ├── modules/
    │   ├── vm.bicep                  # Creates NIC and Virtual Machine
    │   └── vnet.bicep                # References existing VNet, outputs subnet ID
    └── parameters/
        └── vm.bicepparam             # Parameter values (password via env variable)
```

---

## How to Supply the Password

The admin password is **never stored in any file**. It is read from an environment variable at deploy time.

**Step 1 — Set the environment variable:**

PowerShell:
```powershell
$env:VM_PASSWORD = "YourSecurePassword123!"
```

Bash / Azure Cloud Shell:
```bash
export VM_PASSWORD="YourSecurePassword123!"
```

**Step 2 — Deploy:**
```powershell
az deployment group create `
  --resource-group jenkins-rg `
  --template-file production/main.bicep `
  --parameters production/parameters/vm.bicepparam
```

> The `vm.bicepparam` file reads the password via `readEnvironmentVariable('VM_PASSWORD')`, so the environment variable must be set in the same terminal session before deploying.

---

## Parameters Reference

| Parameter | Source | Description |
|-----------|--------|-------------|
| `name` | `parameters/vm.bicepparam` | VM name (e.g. `worker-02-vm`) |
| `username` | `parameters/vm.bicepparam` | Admin username (e.g. `saurav`) |
| `password` | Environment variable `VM_PASSWORD` | Admin password — never hardcoded |
| `existingVnetName` | `parameters/vm.bicepparam` | Name of the existing VNet |
| `existingSubnetName` | `parameters/vm.bicepparam` | Name of the existing Subnet |
| `location` | `main.bicep` (default) | Defaults to the resource group's location |

---

## Password Requirements (Azure Policy)

The password must satisfy Azure's complexity rules:
- At least **12 characters**
- Must contain: **uppercase**, **lowercase**, **digit**, and **special character**
- Must not contain the username
