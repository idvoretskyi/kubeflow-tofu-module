provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "kustomization" {
  kubeconfig_path = var.kubeconfig_path
}
