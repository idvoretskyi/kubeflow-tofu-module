# Kubeflow OpenTofu Module

Deploy Kubeflow on any Kubernetes cluster with OpenTofu/Terraform.

## Prerequisites

- OpenTofu >= 1.6.0 (or Terraform >= 1.6.0)
- Kubernetes cluster with `kubectl` access
- 2+ vCPUs, 8+ GB RAM (for Pipelines only; more for full stack)

## Repository Structure

- `modules/kubeflow`: implementation module with resources, variables, outputs, and provider requirements
- `examples/minimal`: minimal cert-manager + pipelines usage
- `examples/full-stack`: full-stack usage with Istio and optional Kubeflow components
- Root module: wrapper entrypoint with provider configuration and pass-through variables/outputs

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu apply
```

Defaults: deploys cert-manager + Kubeflow Pipelines. That's it.

```bash
# Access Pipelines UI
kubectl port-forward -n kubeflow svc/ml-pipeline-ui 8080:80
open http://localhost:8080
```

## Full Stack (with Istio + Dashboard + Auth)

Set `enable_istio = true` and enable the components you want:

```hcl
enable_istio             = true
enable_pipelines         = true
enable_central_dashboard = true
enable_profiles          = true
enable_admission_webhook = true
enable_notebooks         = true
```

```bash
# Access via Istio
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
open http://localhost:8080
```

## Variables

| Name | Description | Default |
| ---- | ----------- | ------- |
| `kubeflow_version` | Version to deploy (`X.Y` or `latest`) | `"1.11"` |
| `kubeflow_namespace` | Namespace for Kubeflow | `"kubeflow"` |
| `enable_cert_manager` | Deploy cert-manager | `true` |
| `enable_istio` | Deploy Istio + Dex + OAuth2-Proxy | `false` |
| `enable_pipelines` | Deploy Kubeflow Pipelines | `true` |
| `enable_central_dashboard` | Deploy Central Dashboard | `false` |
| `enable_profiles` | Deploy Profiles & KFAM | `false` |
| `enable_admission_webhook` | Deploy PodDefaults webhook | `false` |
| `enable_notebooks` | Deploy Notebook Controller + Jupyter | `false` |
| `enable_katib` | Deploy Katib (hyperparameter tuning) | `false` |
| `enable_training_operator` | Deploy Training Operator | `false` |
| `enable_kserve` | Deploy KServe (model serving) | `false` |

## Local Development (Docker Desktop / Colima)

The defaults work out of the box on Docker Desktop Kubernetes or Colima:

```bash
tofu init && tofu apply
```

This deploys cert-manager and Pipelines only, which fits comfortably in 8GB RAM.

## Examples

```bash
cd examples/minimal
tofu init
tofu plan
```

```bash
cd examples/full-stack
tofu init
tofu plan
```

## Pre-Commit Hooks

This repository includes lightweight pre-commit checks for:

- OpenTofu formatting (`tofu fmt -check -recursive`)
- Markdown docs linting (`markdownlint-cli2`)
- Trivy IaC config scanning (`trivy config`)

Setup:

```bash
python3 -m pip install pre-commit
brew install trivy
pre-commit install
pre-commit run --all-files
```

## License

Apache 2.0
