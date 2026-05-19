data "kustomization_build" "oauth2_proxy" {
  count = var.enable_istio ? 1 : 0
  path  = local.oauth2_proxy_url
}

resource "kustomization_resource" "oauth2_proxy" {
  for_each = var.enable_istio ? data.kustomization_build.oauth2_proxy[0].ids : toset([])
  manifest = data.kustomization_build.oauth2_proxy[0].manifests[each.value]
  # wait=false: OAuth2-Proxy includes a Job that exits on completion; waiting for
  # it to become "ready" would cause a timeout. Dex depends_on this resource so
  # ordering is still preserved.
  wait = false

  depends_on = [
    kubernetes_namespace.kubeflow,
    kustomization_resource.cert_manager,
    kustomization_resource.istio,
    time_sleep.wait_for_istio,
  ]
}

data "kustomization_build" "dex" {
  count = var.enable_istio ? 1 : 0
  path  = local.dex_url
}

resource "kustomization_resource" "dex" {
  for_each = var.enable_istio ? data.kustomization_build.dex[0].ids : toset([])
  manifest = data.kustomization_build.dex[0].manifests[each.value]

  depends_on = [
    kubernetes_namespace.kubeflow,
    kustomization_resource.oauth2_proxy,
  ]
}
