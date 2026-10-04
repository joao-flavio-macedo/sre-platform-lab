# OCI setup checklist

The Terraform stack intentionally requires account-specific values instead of guessing them. OKE versions and compatible ARM images vary by region.

## 1. Confirm the account

- This project is locked to the tenancy home region `sa-saopaulo-1`.
- Confirm that `VM.Standard.A1.Flex` is marked Always Free eligible.
- Check existing Compute instances and boot volumes before creating the cluster.
- Create a budget alert even when the expected cost is zero.

The initial cloud deployment requests one worker with 1 OCPU, 6 GB RAM and a 50 GB boot volume. A single worker is intentional: this is a lab, and the local Kind environment covers multi-node exercises without consuming cloud quota.

The account already contains a VM named `vpn`. Its shape, OCPUs, memory and boot volume must be counted before setting the remaining-capacity variables.

## 2. Configure OCI CLI authentication

Install the OCI CLI and run:

```bash
oci setup config
oci iam region-subscription list
oci iam compartment list --compartment-id-in-subtree true
```

Keep the private API signing key outside this repository. Never commit `~/.oci/config`, private keys, OCIDs from sensitive compartments or Terraform state.

## 3. Inventory current free-tier consumption

List all non-terminated Compute instances in the home region:

```bash
oci compute instance list \
  --compartment-id '<COMPARTMENT_OCID>' \
  --all \
  --query 'data[?"lifecycle-state"!=`TERMINATED`].{name:"display-name",shape:shape,ocpus:"shape-config".ocpus,memory:"shape-config"."memory-in-gbs",state:"lifecycle-state"}' \
  --output table
```

List boot and block volumes and add their sizes:

```bash
oci bv boot-volume list \
  --compartment-id '<COMPARTMENT_OCID>' \
  --availability-domain '<AVAILABILITY_DOMAIN>' \
  --all \
  --query 'data[?"lifecycle-state"!=`TERMINATED`].{name:"display-name",size:"size-in-gbs",state:"lifecycle-state"}' \
  --output table

oci bv volume list \
  --compartment-id '<COMPARTMENT_OCID>' \
  --all \
  --query 'data[?"lifecycle-state"!=`TERMINATED`].{name:"display-name",size:"size-in-gbs",state:"lifecycle-state"}' \
  --output table
```

Repeat the inventory for every compartment containing resources. Set these variables to what remains after existing usage:

- `remaining_free_a1_ocpus`
- `remaining_free_a1_memory_gb`
- `remaining_free_block_storage_gb`

## 4. Discover the current OKE version

```bash
oci ce cluster-options get \
  --cluster-option-id all \
  --query 'data."kubernetes-versions"'
```

Choose a version offered in the home region and copy it to `kubernetes_version` in `terraform.tfvars`.

## 5. Discover a compatible ARM image

```bash
oci ce node-pool-options get \
  --node-pool-option-id all \
  --compartment-id '<COMPARTMENT_OCID>' \
  --query 'data.sources[*].{name:"source-name",id:"image-id"}' \
  --output table
```

Choose an OKE-supported Oracle Linux ARM64 image compatible with the selected Kubernetes version and place its OCID in `node_image_ocid`.

## 6. Prepare variables

```bash
cd infra/oci
cp terraform.tfvars.example terraform.tfvars
```

Set `api_allowed_cidr` to your current public IPv4 address with `/32`. You can obtain it from a trusted IP-check service. The configuration refuses `0.0.0.0/0`.

## 7. Plan before applying

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform show tfplan
```

The plan should contain:

- one VCN, internet gateway, route table, security list and public subnet;
- one `BASIC_CLUSTER` OKE control plane;
- one node pool using `VM.Standard.A1.Flex`;
- one worker using 1 OCPU and 6 GB RAM;
- one 50 GB boot volume.

Stop if Terraform proposes another Compute shape, an enhanced OKE cluster, a NAT Gateway, a load balancer or more capacity than expected. The application remains `ClusterIP` and is accessed initially with `kubectl port-forward`.

## 8. Connect to OKE

After apply, print and run the generated kubeconfig command:

```bash
terraform output -raw configure_kubectl
kubectl get nodes -o wide
```

All nodes should report `arm64`:

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.status.nodeInfo.architecture}{"\n"}{end}'
```

## 9. Cost safety

Budget alerts are notifications, not an automatic spending brake. Review Cost Analysis after provisioning. If eligibility is unclear or the account reports a charge, destroy the stack:

```bash
terraform destroy
```
