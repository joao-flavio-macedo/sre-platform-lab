# Evolution roadmap

## Milestone 1 — Local delivery

- Run unit tests.
- Build the container image.
- Create a three-node Kind cluster.
- Deploy with Helm.
- Prove liveness, readiness and rolling updates.

## Milestone 2 — Continuous integration

- Push the repository to GitHub.
- Run tests, image build, Trivy scan, Helm lint and Terraform validation.
- Publish versioned images to GHCR from Git tags.

## Milestone 3 — GitOps

- Install Argo CD.
- Replace `CHANGE_ME` values with the GitHub owner and repository.
- Apply the Argo CD Application.
- Demonstrate drift correction and rollback through Git.

## Milestone 4 — Observability

- Install kube-prometheus-stack.
- Enable the ServiceMonitor.
- Create a Grafana dashboard and one useful alert.
- Add Loki and structured application logs.

## Milestone 5 — OCI

- Configure the OCI CLI and API signing key.
- Discover an OKE-supported ARM64 node image and Kubernetes version.
- Review `terraform plan` and confirm every Compute shape is Always Free eligible.
- Provision an OKE Basic cluster with two Ampere A1 workers.
- Configure budget alerts and verify the Cost Analysis dashboard.

## Milestone 6 — Production hardening

- Add ingress and TLS.
- Add External Secrets or Vault.
- Add NetworkPolicy and PodDisruptionBudget.
- Sign container images and verify admission policy.
- Add SLOs, alerting and a runbook for one simulated incident.
