# AKS and ACR Terraform

This root deploys a development Azure baseline with one AKS system node and one Standard ACR. The node count is intentionally fixed at `1`; cluster autoscaling is disabled so capacity changes are explicit and reviewed.

## Included

- Azure Resource Group, VNet, AKS subnet, and subnet NSG association
- AKS with Azure CNI Overlay, Azure network policy, Standard Load Balancer, Microsoft Entra RBAC, Azure RBAC, OIDC, workload identity, and Azure Policy
- Azure Linux system node pool using `Standard_DS2_v2`
- User-assigned identity with `AcrPull` scoped only to the ACR
- Standard ACR with admin credentials disabled
- Log Analytics, Container Insights, AKS diagnostics, and 30-day retention by default
- Weekly AKS auto-upgrade maintenance window

## Bootstrap remote state

Create a Storage Account and blob container once, with storage firewall/private endpoint controls appropriate to your organization. The CI workflows expect these GitHub repository variables:

`TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, `TF_STATE_CONTAINER`, and `TF_STATE_KEY`.

The workflows authenticate with Azure using GitHub OIDC. Configure repository secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID`, then create a federated credential for the repository's `pull_request` and `main` subjects. Grant the identity `Contributor` on the deployment resource group/subscription and `Storage Blob Data Contributor` on the state container.

## Local use

```powershell
az login
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init -backend-config="resource_group_name=..." -backend-config="storage_account_name=..." -backend-config="container_name=..." -backend-config="key=aks-dev.tfstate"
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Set `admin_allowed_ip_ranges` to the real public CIDR ranges that need Kubernetes API access. Do not use the example documentation IP in a real deployment. Configure the GitHub `development` environment with required reviewers: that environment is the manual approval gate for apply.