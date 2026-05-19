resource "kubernetes_namespace" "kubeflow" {
  metadata {
    name = var.kubeflow_namespace
  }
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "istio_system" {
  count = var.enable_istio ? 1 : 0

  metadata {
    name = "istio-system"
  }
}
