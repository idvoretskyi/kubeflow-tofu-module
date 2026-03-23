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
