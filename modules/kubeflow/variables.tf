variable "kubeflow_version" {
  description = "Kubeflow version to deploy (e.g., '1.9' or 'latest')"
  type        = string
  default     = "1.11"

  validation {
    condition     = can(regex("^(\\d+\\.\\d+|latest)$", var.kubeflow_version))
    error_message = "Must be 'X.Y' (e.g., '1.9') or 'latest'."
  }
}

variable "kubeflow_namespace" {
  description = "Namespace for Kubeflow components"
  type        = string
  default     = "kubeflow"
}

# Infrastructure toggles

variable "enable_cert_manager" {
  description = "Deploy cert-manager (required by Pipelines and webhooks)"
  type        = bool
  default     = true
}

variable "enable_istio" {
  description = "Deploy Istio, Dex, and OAuth2-Proxy (needed for Dashboard, Notebooks UI, auth)"
  type        = bool
  default     = false
}

# Kubeflow component toggles

variable "enable_pipelines" {
  description = "Deploy Kubeflow Pipelines"
  type        = bool
  default     = true

  validation {
    condition     = !var.enable_pipelines || var.enable_cert_manager
    error_message = "enable_pipelines = true requires enable_cert_manager = true because Pipelines cluster-scoped resources use the cert-manager path and depend on the cert-manager issuer."
  }
}

variable "enable_central_dashboard" {
  description = "Deploy Central Dashboard (requires Istio)"
  type        = bool
  default     = false

  validation {
    condition     = var.enable_istio || !var.enable_central_dashboard
    error_message = "enable_central_dashboard = true requires enable_istio = true, because the Central Dashboard depends on Istio."
  }
}

variable "enable_profiles" {
  description = "Deploy Profiles and KFAM (multi-user namespace management)"
  type        = bool
  default     = false
}

variable "enable_admission_webhook" {
  description = "Deploy PodDefaults admission webhook"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_admission_webhook || var.enable_cert_manager
    error_message = "enable_admission_webhook = true requires enable_cert_manager = true because the admission webhook uses the cert-manager overlay."
  }
}

variable "enable_notebooks" {
  description = "Deploy Notebook Controller and Jupyter Web App (web app requires Istio)"
  type        = bool
  default     = false

  validation {
    condition     = (!var.enable_notebooks) || var.enable_istio
    error_message = "enable_notebooks = true requires enable_istio = true because the Jupyter Web App depends on the Istio overlay."
  }
}

variable "enable_katib" {
  description = "Deploy Katib for hyperparameter tuning"
  type        = bool
  default     = false
}

variable "enable_training_operator" {
  description = "Deploy Training Operator (TFJob, PyTorchJob, etc.)"
  type        = bool
  default     = false
}

variable "enable_kserve" {
  description = "Deploy KServe for model serving"
  type        = bool
  default     = false
}

# Training Operator tuning

variable "training_operator_webhook_failure_policy" {
  description = <<-EOT
    failurePolicy for the training-operator ValidatingWebhookConfiguration.
    The default value 'Fail' is correct for self-managed clusters where the
    API server can reach in-cluster services.

    Set to 'Ignore' on managed Kubernetes (Akamai LKE, GKE, EKS, AKS, etc.)
    where the managed control plane cannot reliably reach in-cluster ClusterIP /
    pod CIDRs. In those environments every webhook call for TrainingJob resources
    (PyTorchJob, TFJob, etc.) times out, even when training-operator is healthy.

    Values: 'Fail' (strict, default) | 'Ignore' (permissive, for managed K8s).
  EOT
  type        = string
  default     = "Fail"

  validation {
    condition     = contains(["Fail", "Ignore"], var.training_operator_webhook_failure_policy)
    error_message = "training_operator_webhook_failure_policy must be 'Fail' or 'Ignore'."
  }
}

# cert-manager tuning

variable "cert_manager_wait_seconds" {
  description = "Seconds to wait after the cert-manager webhook deployment becomes Available before creating dependent resources (ClusterIssuer, Pipelines, etc.). A short buffer is needed because the webhook process requires a moment to begin serving after the Deployment readiness gate passes."
  type        = number
  default     = 30
}

variable "cert_manager_webhook_failure_policy" {
  description = <<-EOT
    failurePolicy for cert-manager admission webhooks (ValidatingWebhookConfiguration
    and MutatingWebhookConfiguration). The default value 'Fail' is correct for
    self-managed clusters where the API server can reach in-cluster services.

    Set to 'Ignore' on managed Kubernetes (Akamai LKE, GKE, EKS, AKS, etc.) where
    the managed control plane cannot reliably reach in-cluster ClusterIP/pod CIDRs.
    In those environments every cert-manager webhook call times out, causing
    ClusterIssuer and Certificate creation to fail even though cert-manager itself
    is fully healthy.

    Values: 'Fail' (strict, default) | 'Ignore' (permissive, for managed K8s).
  EOT
  type        = string
  default     = "Fail"

  validation {
    condition     = contains(["Fail", "Ignore"], var.cert_manager_webhook_failure_policy)
    error_message = "cert_manager_webhook_failure_policy must be 'Fail' or 'Ignore'."
  }
}
