# Kubeflow OpenTofu Module

[![CI](https://github.com/idvoretskyi/kubeflow-tofu-module/actions/workflows/ci.yml/badge.svg)](https://github.com/idvoretskyi/kubeflow-tofu-module/actions/workflows/ci.yml)
[![Security](https://github.com/idvoretskyi/kubeflow-tofu-module/actions/workflows/security.yml/badge.svg)](https://github.com/idvoretskyi/kubeflow-tofu-module/actions/workflows/security.yml)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6-purple?logo=opentofu)](https://opentofu.org)
[![Kubeflow](https://img.shields.io/badge/Kubeflow-1.11-blue?logo=kubeflow)](https://www.kubeflow.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Deploy Kubeflow on any Kubernetes cluster with OpenTofu (or Terraform).

Defaults: **cert-manager + Kubeflow Pipelines**. Everything else is opt-in.

## Prerequisites

- OpenTofu >= 1.6.0 (or Terraform >= 1.6.0)
- Kubernetes cluster accessible via `kubectl` (`kubectl` must be on `PATH`)
- 2+ vCPUs, 8+ GB RAM for Pipelines only; more for a full stack

## Repository Structure

```
.
├── modules/kubeflow/   # Implementation: resources, variables, outputs, providers
├── examples/
│   ├── minimal/                  # cert-manager + Pipelines (default)
│   ├── full-stack/               # All components with Istio
│   ├── pytorch-mnist-gpu/        # PyTorchJob MNIST demo (GPU, Training Operator)
│   └── kfp-iris-pipeline/        # KFP v2 Python SDK pipeline demo
├── main.tf             # Root wrapper module
├── variables.tf        # Root pass-through variables
├── outputs.tf          # Root pass-through outputs
└── versions.tf         # Provider version constraints
```

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu apply
```

Deploys cert-manager and Kubeflow Pipelines into the `kubeflow` namespace.

```bash
# Access the Pipelines UI
kubectl port-forward -n kubeflow svc/ml-pipeline-ui 8080:80
open http://localhost:8080
```

## Full Stack (Istio + Dashboard + Auth)

```hcl
enable_istio             = true
enable_pipelines         = true
enable_central_dashboard = true
enable_profiles          = true
enable_admission_webhook = true
enable_notebooks         = true
```

```bash
# Access via Istio ingress
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
open http://localhost:8080
```

## Variables

### Core

| Name | Description | Default |
| ---- | ----------- | ------- |
| `kubeflow_version` | Version to deploy (`X.Y` or `latest`) | `"1.11"` |
| `kubeflow_namespace` | Namespace for Kubeflow components | `"kubeflow"` |

### Component toggles

| Name | Description | Default |
| ---- | ----------- | ------- |
| `enable_cert_manager` | Deploy cert-manager | `true` |
| `enable_istio` | Deploy Istio + Dex + OAuth2-Proxy | `false` |
| `enable_pipelines` | Deploy Kubeflow Pipelines | `true` |
| `enable_central_dashboard` | Deploy Central Dashboard (requires Istio) | `false` |
| `enable_profiles` | Deploy Profiles & KFAM | `false` |
| `enable_admission_webhook` | Deploy PodDefaults webhook | `false` |
| `enable_notebooks` | Deploy Notebook Controller + Jupyter Web App | `false` |
| `enable_katib` | Deploy Katib (hyperparameter tuning) | `false` |
| `enable_training_operator` | Deploy Training Operator (PyTorchJob, TFJob, …) | `false` |
| `enable_kserve` | Deploy KServe (model serving) | `false` |

### Managed Kubernetes tuning

| Name | Description | Default |
| ---- | ----------- | ------- |
| `cert_manager_wait_seconds` | Post-readiness buffer (seconds) before creating cert-manager issuer and dependents | `30` |
| `cert_manager_webhook_failure_policy` | cert-manager webhook failure policy; set `"Ignore"` on managed K8s | `"Fail"` |
| `training_operator_webhook_failure_policy` | Training Operator webhook failure policy; set `"Ignore"` on managed K8s | `"Fail"` |

## Examples

### Minimal — cert-manager + Pipelines

```bash
cd examples/minimal
tofu init && tofu plan
```

### Full Stack — all components with Istio

```bash
cd examples/full-stack
tofu init && tofu plan
```

### PyTorchJob MNIST GPU demo

Validates the Training Operator, GPU scheduling, and CUDA access end-to-end.
Trains a 3-epoch CNN on MNIST and expects ~98.9% test accuracy.

```bash
kubectl apply -f examples/pytorch-mnist-gpu/pytorchjob.yaml
kubectl logs -n kubeflow mnist-gpu-demo-master-0 -f
```

Requires `enable_training_operator = true` and at least one GPU node.

### KFP v2 Iris classification pipeline

Submits a 3-step DAG pipeline (data-prep → train → evaluate) via the KFP
Python SDK and logs accuracy metrics visible in the Pipelines UI.

```bash
pip install "kfp>=2.11"
kubectl port-forward -n kubeflow svc/ml-pipeline 8888:8888 &
python3 examples/kfp-iris-pipeline/pipeline.py
```

Expected metrics: `train_samples=120`, `test_samples=30`, `accuracy_pct=90.0`.

## Managed Kubernetes (LKE / GKE / EKS / AKS)

On managed Kubernetes the API server runs outside the cluster and cannot
reliably reach in-cluster ClusterIP services. Admission webhook calls therefore
time out, even when the target pods are fully healthy.

Set both webhook failure-policy variables to `"Ignore"`:

```hcl
module "kubeflow" {
  source = "github.com/idvoretskyi/kubeflow-tofu-module//modules/kubeflow"

  cert_manager_webhook_failure_policy      = "Ignore"
  training_operator_webhook_failure_policy = "Ignore"

  enable_pipelines         = true
  enable_training_operator = true
}
```

The module will patch the relevant `ValidatingWebhookConfiguration` and
`MutatingWebhookConfiguration` resources after install so that timeouts are
non-fatal. This is safe: the resources validated by these webhooks are
well-formed when emitted by the kustomization provider.

## Local Development (Docker Desktop / Colima)

The defaults work out of the box on Docker Desktop Kubernetes or Colima:

```bash
tofu init && tofu apply
```

Deploys cert-manager and Pipelines only, which fits comfortably in 8 GB RAM.

## Pre-Commit Hooks

Lightweight pre-commit checks cover:

- OpenTofu formatting (`tofu fmt -check -recursive`)
- Markdown linting (`markdownlint-cli2`)
- Trivy IaC scanning (`trivy config`)

```bash
python3 -m pip install pre-commit
brew install trivy
pre-commit install
pre-commit run --all-files
```

## License

[Apache 2.0](LICENSE)
