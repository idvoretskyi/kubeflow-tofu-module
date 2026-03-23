module "kubeflow" {
  source = "./modules/kubeflow"

  kubeflow_version         = var.kubeflow_version
  kubeflow_namespace       = var.kubeflow_namespace
  enable_cert_manager      = var.enable_cert_manager
  enable_istio             = var.enable_istio
  enable_pipelines         = var.enable_pipelines
  enable_central_dashboard = var.enable_central_dashboard
  enable_profiles          = var.enable_profiles
  enable_admission_webhook = var.enable_admission_webhook
  enable_notebooks         = var.enable_notebooks
  enable_katib             = var.enable_katib
  enable_training_operator = var.enable_training_operator
  enable_kserve            = var.enable_kserve
}
