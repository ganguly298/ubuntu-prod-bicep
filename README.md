# Azure VM Bicep Deployment

Deploys a Windows 11 Pro Virtual Machine (`Standard_B2s_v2`) into a freshly created Virtual Network + Subnet, attaches a Network Security Group (NSG) to the subnet, and stores the auto-generated admin password in Azure Key Vault. The password is never hardcoded — the VM reads it directly from Key Vault at deploy time.

---

## Reusing this template

To deploy another VM with the same template, **just change `name` in [production/parameters/prod.bicepparam](production/parameters/prod.bicepparam) before running the deployment**. Everything else (VM name, NIC name, Public IP name, Key Vault secret name) is derived from `name` and stays unique per VM.

```bicep
param name = 'worker-10-vm'   // change this — that's it
```

Then re-run the same `az deployment group create` command.

---

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in
  ```powershell
  az login
  az account set --subscription <your-subscription-id>
  ```
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) (bundled with Azure CLI 2.20+)
- An existing **Azure Resource Group** (e.g. `jenkins-rg`)

> The VNet, Subnet, NSG, Key Vault, NIC, Public IP, and VM are all created by this template — you only need the resource group.

---

## File Structure

```
bicep-test/
├── README.md
└── production/
    ├── main.bicep                    # Entry point — wires all modules together
    ├── modules/
    │   ├── keyvault.bicep            # Key Vault + password secret
    │   ├── nsg.bicep                 # Network Security Group (allows RDP 3389)
    │   ├── vnet.bicep                # VNet + Subnet (NSG attached)
    │   └── vm.bicep                  # Public IP, NIC, and Virtual Machine
    └── parameters/
        └── prod.bicepparam           # All parameter values for the deployment
```

---

## Deploy Order (handled automatically by Bicep)

1. **Key Vault** is deployed and the auto-generated password is stored as the secret `pass-vm-<name>`.
2. **NSG** is deployed (`<subnetName>-nsg`) with an inbound RDP (3389) allow rule.
3. **VNet + Subnet** is deployed, with the NSG attached to the subnet.
4. **VM** is deployed — NIC + Static Public IP created, password pulled from Key Vault via `kv.getSecret('pass-vm-<name>')`.

---

## How the Password Works

- Generated in [production/main.bicep](production/main.bicep) as:
  ```bicep
  var generatedPassword = 'Pwd-${uniqueString(resourceGroup().id, deployment().name)}1!'
  ```
- Stored in Key Vault as secret `pass-vm-<name>` by [production/modules/keyvault.bicep](production/modules/keyvault.bicep).
- Consumed by the VM via `kv.getSecret('pass-vm-<name>')` — never passed through a plain variable.

To retrieve the password after deployment:
```powershell
az keyvault secret show --vault-name myKeyvault-296a --name pass-vm-<name> --query value -o tsv
```

> Default Key Vault name is `myKeyvault-296a` (set in `main.bicep`). Change `kvName` if you need a different vault.

---

## Parameters Reference

All values live in [production/parameters/prod.bicepparam](production/parameters/prod.bicepparam):

| Parameter | Description |
|-----------|-------------|
| `name` | VM base name — actual VM name becomes `vm-<name>`. **Change this to deploy a new VM.** |
| `username` | Admin username |
| `vnetName` | Name of the VNet to create |
| `subnetName` | Name of the subnet to create (NSG named `<subnetName>-nsg`) |
| `vnetAddressPrefix` | VNet CIDR (e.g. `10.0.0.0/16`) |
| `subnetAddressPrefix` | Subnet CIDR (e.g. `10.0.0.0/24`) |

Defaults in [production/main.bicep](production/main.bicep):

| Parameter | Default |
|-----------|---------|
| `location` | `resourceGroup().location` |
| `kvName` | `myKeyvault-296a` |

---

## Deploying

**PowerShell (multi-line):**
```powershell
az deployment group create `
  --resource-group jenkins-rg `
  --template-file production/main.bicep `
  --parameters production/parameters/prod.bicepparam
```

**One-liner:**
```bash
az deployment group create --resource-group jenkins-rg --template-file production/main.bicep --parameters production/parameters/prod.bicepparam
```

---

## Finding the Right VM Image

The template is currently set to Windows 11 Pro (`microsoftwindowsdesktop` / `windows-11` / `win11-25h2-pro`) in [production/modules/vm.bicep](production/modules/vm.bicep). To switch images, use the steps below.

### Windows 11 (Desktop)

```powershell
# Publisher
az vm image list-publishers --location centralindia --query "[?contains(name, 'Windows')].name" --output table
# Offer
az vm image list-offers --location centralindia --publisher microsoftwindowsdesktop --output table
# SKU
az vm image list-skus --location centralindia --publisher microsoftwindowsdesktop --offer windows-11 --output table
```

### Ubuntu / Linux (Canonical)

```powershell
# Publisher
az vm image list-publishers --location centralindia --query "[?contains(name, 'Canonical')].name" --output table
# Offer
az vm image list-offers --location centralindia --publisher Canonical --output table
# SKU
az vm image list-skus --location centralindia --publisher Canonical --offer ubuntu-24_04-lts --output table
```

Then update the `imageReference` block in [production/modules/vm.bicep](production/modules/vm.bicep).

---

## Notes / Gotchas

- **Public IP quota:** Each deployment currently creates a new Public IP (name includes `uniqueString(deployment().name)`), so re-deploys may hit the subscription's Public IP quota. Delete unattached PIPs with:
  ```powershell
  az network public-ip list --query "[?ipConfiguration==null].[name,resourceGroup]" -o tsv |
    ForEach-Object { $n,$r = $_ -split "`t"; az network public-ip delete -g $r -n $n }
  ```
- **Key Vault soft-delete:** Secret names are scoped per VM (`pass-vm-<name>`). If you redeploy with the same `name` after deleting the secret, you may need to purge the soft-deleted secret first:
  ```powershell
  az keyvault secret purge --vault-name myKeyvault-296a --name pass-vm-<name>
  ```
- **NSG rule:** Currently allows RDP (TCP 3389) from any source. Tighten `sourceAddressPrefix` in [production/modules/nsg.bicep](production/modules/nsg.bicep) for production use.
