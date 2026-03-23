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
  enable_istio             = true
  enable_pipelines         = true
  enable_central_dashboard = true
  enable_profiles          = true
  enable_admission_webhook = true
  enable_notebooks         = true
  enable_katib             = true
  enable_training_operator = true
  enable_kserve            = true
}
