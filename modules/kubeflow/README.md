# kubeflow module

Reusable OpenTofu module that deploys Kubeflow components to an existing Kubernetes cluster using the Kubernetes and Kustomization providers.

## Usage

```hcl
module "kubeflow" {
  source = "./modules/kubeflow"

  kubeflow_version    = "1.11"
  kubeflow_namespace  = "kubeflow"
  enable_cert_manager = true
  enable_istio        = false
  enable_pipelines    = true
}
```

## Notes

- This module does not configure providers. Configure providers in the root module and pass credentials/paths there.
- `enable_istio = true` also enables required auth prerequisites (Dex and OAuth2-Proxy resources).
- Deployment order is enforced via `depends_on`: namespaces → cert-manager (+ 90 s wait) → Istio (+ 120 s wait) → auth → Kubeflow components.

## File structure

| File | Contents |
| ---- | -------- |
| `locals.tf` | Manifest URL construction and cert-manager ID filtering |
| `namespaces.tf` | `kubeflow`, `cert-manager`, and `istio-system` namespaces |
| `cert_manager.tf` | cert-manager install, 90 s readiness wait, and Kubeflow issuer |
| `istio.tf` | Istio CRDs → namespace → install → Kubeflow resources, 120 s wait |
| `auth.tf` | OAuth2-Proxy and Dex (enabled when `enable_istio = true`) |
| `pipelines.tf` | Cluster-scoped resources, cache-deployer RBAC, pipeline workloads |
| `components.tf` | Dashboard, Profiles, Admission Webhook, Notebooks, Katib, Training Operator, KServe |
| `variables.tf` | All input variables |
| `outputs.tf` | Namespace, access instructions, component status map |
| `versions.tf` | Provider version constraints |

## Inputs

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `kubeflow_version` | `string` | `"1.11"` | Kubeflow version to deploy (`X.Y` or `latest`) |
| `kubeflow_namespace` | `string` | `"kubeflow"` | Namespace for Kubeflow components |
| `enable_cert_manager` | `bool` | `true` | Deploy cert-manager (required by Pipelines and webhooks) |
| `enable_istio` | `bool` | `false` | Deploy Istio, Dex, and OAuth2-Proxy (needed for Dashboard, Notebooks UI, auth) |
| `enable_pipelines` | `bool` | `true` | Deploy Kubeflow Pipelines |
| `enable_central_dashboard` | `bool` | `false` | Deploy Central Dashboard (requires Istio) |
| `enable_profiles` | `bool` | `false` | Deploy Profiles and KFAM (multi-user namespace management) |
| `enable_admission_webhook` | `bool` | `false` | Deploy PodDefaults admission webhook |
| `enable_notebooks` | `bool` | `false` | Deploy Notebook Controller and Jupyter Web App (web app requires Istio) |
| `enable_katib` | `bool` | `false` | Deploy Katib for hyperparameter tuning |
| `enable_training_operator` | `bool` | `false` | Deploy Training Operator (TFJob, PyTorchJob, etc.) |
| `enable_kserve` | `bool` | `false` | Deploy KServe for model serving |

## Outputs

| Name | Description |
| ---- | ----------- |
| `kubeflow_namespace` | Namespace where Kubeflow is deployed |
| `access_instructions` | How to access the Kubeflow UI via `kubectl port-forward` |
| `enabled_components` | Map of component name → bool indicating which components are deployed |
