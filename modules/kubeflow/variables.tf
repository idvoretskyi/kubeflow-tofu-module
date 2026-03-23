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
