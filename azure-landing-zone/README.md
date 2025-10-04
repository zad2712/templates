# Azure Landing Zone (Terraform)

This directory contains a modular Azure Landing Zone implementation aligned with Azure Well-Architected Framework (WAF) pillars: Cost, Operational Excellence, Performance Efficiency, Reliability, and Security.

## Modules
- networking: Hub virtual network, subnets, optional firewall/bastion (toggles)
- logging: Log Analytics workspace and diagnostic settings helper
- security: Shared Key Vault (RBAC), optional private endpoints (future)
- identity: User-assigned managed identities and role assignments
- management: (Optional) management group hierarchy seed
- policy: Baseline policy initiative (tag enforcement, allowed locations, diagnostics)

## Getting Started
1. Select your environment (e.g. dev):
   ```powershell
   cd azure-landing-zone
   Copy-Item .\environments\dev\terraform.tfvars.example .\terraform.tfvars -Force
   ```
2. (Optional) Adjust variables in `terraform.tfvars`.
3. Initialize with per-environment backend (edit backend.conf values first):
   ```powershell
   terraform init -backend-config=environments/dev/backend.conf
   ```
4. Review plan:
   ```powershell
   terraform plan -out plan.tfplan
   ```
5. Apply:
   ```powershell
   terraform apply plan.tfplan
   ```

### Remote State Backend
Per-environment backend configuration files are stored under `environments/<env>/backend.conf`:
```
resource_group_name  = "rg-tfstate"
storage_account_name = "sttfstate1234"
container_name       = "tfstate"
key                  = "landing-zone/<env>.tfstate"
```
Update these to match your actual remote state storage resources before running `terraform init`.

## Naming & Tagging
A consistent naming convention (org + env + location + resource) is generated via locals.
Common tags enforced by policy and applied in all modules.

## Security Considerations
- Key Vault: purge protection + soft delete enabled
- Diagnostics: Policy ensures resource types emit to Log Analytics
- Least privilege: Role assignments driven from input maps
- No secrets stored in code/state beyond resource IDs

## Extensibility Roadmap
- Private endpoints for Key Vault / Storage
- Azure Firewall Premium & Policy collection
- Spoke VNet module patterns
- Defender for Cloud plan enablement

Refer to each module's README (inline comments) for details.
