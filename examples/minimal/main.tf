terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "~> 0.9"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

provider "kubernetes" {}
provider "kustomization" {}

module "kubeflow" {
  source = "../.."

  kubeflow_version         = "1.11"
  enable_cert_manager      = true
  enable_istio             = false
  enable_pipelines         = true
  enable_central_dashboard = false
  enable_profiles          = false
  enable_admission_webhook = false
  enable_notebooks         = false
  enable_katib             = false
  enable_training_operator = false
  enable_kserve            = false
}
