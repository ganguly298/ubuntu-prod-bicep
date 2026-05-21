# Azure VM Bicep Deployment

Deploys an Ubuntu 24.04 LTS Virtual Machine (`Standard_B2s_v2`) into an **existing** Virtual Network and Subnet using Azure Bicep. A Key Vault is automatically created and the VM password is auto-generated, stored in Key Vault, and referenced from there — never hardcoded anywhere.

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

This deployment does **not** create a new VNet. You must have an existing VNet and Subnet. Update the values in `production/parameters/prod.bicepparam` to match your environment:

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
    ├── main.bicep                    # Entry point — wires all modules together
    ├── modules/
    │   ├── vm.bicep                  # Creates NIC and Virtual Machine
    │   ├── vnet.bicep                # References existing VNet, outputs subnet ID
    │   └── keyvault.bicep            # Deploys Azure Key Vault
    └── parameters/
        └── prod.bicepparam           # All parameter values for the deployment
```

---

## How the Password Works

The password is **auto-generated** at deploy time using `uniqueString()` — you never set it manually. The flow is:

1. `main.bicep` generates the password as a variable
2. Key Vault is deployed via `keyvault.bicep`
3. Password is stored as secret `vm-password` in Key Vault
4. VM module reads the password using `kv.getSecret('vm-password')` — never from the variable directly

To retrieve the password after deployment:
```bash
az keyvault secret show --vault-name <kv-name> --name vm-password --query value -o tsv
```

> The KV name is auto-generated too: `kv-<uniqueString>`. Find it in the Azure Portal under `jenkins-rg`.

---

## Deploying

A **single command** deploys everything — Key Vault, password secret, VNet lookup, and VM:

```bash
az deployment group create \
  --resource-group jenkins-rg \
  --template-file production/main.bicep \
  --parameters production/parameters/prod.bicepparam
```

### Deploy order (handled automatically by Bicep)
1. Key Vault is created (`keyvault.bicep`)
2. Generated password is stored as `vm-password` secret in KV
3. Existing VNet/Subnet is resolved (`vnet.bicep`)
4. VM is created — password fetched via `kv.getSecret('vm-password')` (`vm.bicep`)

---

## Parameters Reference

| Parameter | File | Description |
|-----------|------|-------------|
| `name` | `prod.bicepparam` | VM base name — actual VM name becomes `vm-<name>` |
| `username` | `prod.bicepparam` | Admin username (e.g. `saurav`) |
| `existingVnetName` | `prod.bicepparam` | Name of the existing VNet |
| `existingSubnetName` | `prod.bicepparam` | Name of the existing Subnet |
| `kvName` | `main.bicep` (auto) | KV name — auto-generated via `uniqueString()` |
| `location` | `main.bicep` (default) | Defaults to the resource group's location |
| `password` | Auto-generated + KV | Never set manually — generated and stored in KV |

---

## Password Requirements (Azure Policy)

The auto-generated password already satisfies Azure's complexity rules:
- At least **12 characters**
- Contains **uppercase**, **lowercase**, **digit**, and **special character**
- Does not contain the username
