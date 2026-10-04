# SRE Platform Lab

A portfolio project that demonstrates the complete path from source code to an observable Kubernetes workload:

`code -> test -> container -> security scan -> registry -> Helm -> Argo CD -> Kubernetes -> Prometheus`

The application is intentionally small. The engineering value is in delivery, infrastructure, operations and troubleshooting.

## What this repository proves

- A tested FastAPI service with health checks and Prometheus metrics.
- A non-root, constrained container image.
- A Helm deployment with rolling updates, probes and resource controls.
- CI validation for code, container security, Helm and Terraform.
- Image publishing to GitHub Container Registry.
- Declarative GitOps delivery with Argo CD.
- OCI VCN and OKE infrastructure defined with Terraform.
- Multi-architecture images for local AMD64 and OCI Ampere ARM64 workers.

## Repository structure

```text
app/                 Application and metrics
tests/               Automated tests
helm/platform-api/   Kubernetes packaging
argocd/              GitOps Application
infra/local/         Local Kind cluster
infra/oci/           OCI VCN and OKE
.github/workflows/   CI and image release
docs/                Learning and implementation roadmap
```

## Quick start: application

Requirements: Python 3.13 and GNU Make.

On Windows, use Ubuntu in WSL2 and enable Docker Desktop's WSL integration. Run the repository, `make`, Kind, kubectl, Helm and Terraform from the WSL terminal so the local workflow matches Linux CI and the OCI worker environment.

```bash
make install
make test
make run
```

Test the endpoints:

```bash
curl http://localhost:8000/
curl http://localhost:8000/health/live
curl http://localhost:8000/health/ready
curl http://localhost:8000/metrics
```

## Quick start: local Kubernetes

Requirements: Docker, Kind, kubectl and Helm.

```bash
make kind-up
make deploy
kubectl -n platform-api get pods,svc
make port-forward
```

Then open `http://localhost:8000` in another terminal. Remove the cluster with `make clean`.

## GitHub and GitOps setup

1. Create a GitHub repository named `sre-platform-lab`.
2. Replace `CHANGE_ME` in `helm/platform-api/values.yaml` and `argocd/application.yaml`.
3. Push the repository and confirm all CI jobs pass.
4. Create a Git tag such as `v0.1.0` to publish the image to GHCR.
5. Install Argo CD and apply `argocd/application.yaml`.

The Argo CD Application has automated synchronization, pruning and self-healing enabled. Production environments would normally add approval and promotion controls.

## OCI PAYG deployment with a zero-cost target

The Terraform design is locked to the tenancy home region, `sa-saopaulo-1`, and starts with one Ampere A1 worker using 1 OCPU, 6 GB and a 50 GB boot volume. The exact Always Free allowance and remaining capacity depend on current Oracle terms and resources already running in the account.

The stack deliberately avoids NAT Gateway, Bastion, public LoadBalancer and paid OKE features. The API is initially reached through `kubectl port-forward`.

Configure the OCI CLI, create or select a compartment, and discover the current Kubernetes version and an OKE-compatible ARM64 image. Then:

```bash
cd infra/oci
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
```

The example intentionally rejects `0.0.0.0/0` for Kubernetes API access. Set `api_allowed_cidr` to your public IP followed by `/32`.

Only run `terraform apply` after inventorying the existing `vpn` instance and all boot/block volumes. Terraform requires the remaining free capacity and refuses a worker request larger than those declared values.

```bash
terraform destroy
```

## Interview narrative

> I built a reproducible delivery platform around a small API. Every change is tested, containerized and security-scanned. Kubernetes deployment is packaged with Helm, reconciled by Argo CD and observable through Prometheus. Infrastructure is defined in Terraform, with a zero-cost local path and an OCI OKE path on Ampere ARM workers. I can demonstrate multi-architecture delivery, deployment, rollback, drift correction and incident troubleshooting.

See [docs/oci-setup.md](docs/oci-setup.md) for OCI preparation and cost safeguards, and [docs/roadmap.md](docs/roadmap.md) for the staged implementation plan.
