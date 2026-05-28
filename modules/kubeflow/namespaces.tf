resource "kubernetes_namespace_v1" "kubeflow" {
  metadata {
    name = var.kubeflow_namespace
  }
}

resource "kubernetes_namespace_v1" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace_v1" "istio_system" {
  count = var.enable_istio ? 1 : 0

  metadata {
    name = "istio-system"
  }
}
