data "kustomization_build" "istio_crds" {
  count = var.enable_istio ? 1 : 0
  path  = local.istio_crds_url
}

resource "kustomization_resource" "istio_crds" {
  for_each = var.enable_istio ? data.kustomization_build.istio_crds[0].ids : toset([])
  manifest = data.kustomization_build.istio_crds[0].manifests[each.value]
}

data "kustomization_build" "istio_namespace" {
  count = var.enable_istio ? 1 : 0
  path  = local.istio_namespace_url
}

resource "kustomization_resource" "istio_namespace" {
  for_each = var.enable_istio ? data.kustomization_build.istio_namespace[0].ids : toset([])
  manifest = data.kustomization_build.istio_namespace[0].manifests[each.value]

  depends_on = [kustomization_resource.istio_crds]
}

data "kustomization_build" "istio" {
  count = var.enable_istio ? 1 : 0
  path  = local.istio_install_url
}

resource "kustomization_resource" "istio" {
  for_each = var.enable_istio ? data.kustomization_build.istio[0].ids : toset([])
  manifest = data.kustomization_build.istio[0].manifests[each.value]

  depends_on = [
    kustomization_resource.istio_namespace,
    kustomization_resource.cert_manager,
  ]
}

data "kustomization_build" "kubeflow_istio_resources" {
  count = var.enable_istio ? 1 : 0
  path  = local.istio_resources_url
}

resource "kustomization_resource" "kubeflow_istio_resources" {
  for_each = var.enable_istio ? data.kustomization_build.kubeflow_istio_resources[0].ids : toset([])
  manifest = data.kustomization_build.kubeflow_istio_resources[0].manifests[each.value]

  depends_on = [
    kustomization_resource.istio,
    kubernetes_namespace_v1.kubeflow,
  ]
}

resource "time_sleep" "wait_for_istio" {
  count           = var.enable_istio ? 1 : 0
  create_duration = "120s"

  depends_on = [kustomization_resource.istio]
}
