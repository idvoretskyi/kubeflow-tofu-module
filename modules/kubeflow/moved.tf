# State migration: kubernetes_namespace -> kubernetes_namespace_v1
# These moved blocks ensure existing users do not see destroy/recreate
# when upgrading to this version of the module.

moved {
  from = kubernetes_namespace.kubeflow
  to   = kubernetes_namespace_v1.kubeflow
}

moved {
  from = kubernetes_namespace.cert_manager
  to   = kubernetes_namespace_v1.cert_manager
}

moved {
  from = kubernetes_namespace.istio_system
  to   = kubernetes_namespace_v1.istio_system
}
