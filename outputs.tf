output "kubeflow_namespace" {
  description = "Namespace where Kubeflow is deployed"
  value       = kubernetes_namespace.kubeflow.metadata[0].name
}

output "access_instructions" {
  description = "How to access Kubeflow"
  value = (
    var.enable_istio
    ? "kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80\nOpen http://localhost:8080\nLogin: user@example.com / 12341234"
    : var.enable_pipelines
    ? "kubectl port-forward -n ${var.kubeflow_namespace} svc/ml-pipeline-ui 8080:80\nOpen http://localhost:8080"
    : "No UI components enabled."
  )
}

output "enabled_components" {
  description = "Which components are deployed"
  value = {
    cert_manager      = var.enable_cert_manager
    istio             = var.enable_istio
    pipelines         = var.enable_pipelines
    central_dashboard = var.enable_central_dashboard
    profiles          = var.enable_profiles
    admission_webhook = var.enable_admission_webhook
    notebooks         = var.enable_notebooks
    katib             = var.enable_katib
    training_operator = var.enable_training_operator
    kserve            = var.enable_kserve
  }
}
