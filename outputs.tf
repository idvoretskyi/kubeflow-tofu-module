output "kubeflow_namespace" {
  description = "Namespace where Kubeflow is deployed"
  value       = module.kubeflow.kubeflow_namespace
}

output "access_instructions" {
  description = "How to access Kubeflow"
  value       = module.kubeflow.access_instructions
}

output "enabled_components" {
  description = "Which components are deployed"
  value       = module.kubeflow.enabled_components
}
