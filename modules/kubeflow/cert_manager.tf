data "kustomization_build" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  path  = local.cert_manager_url
}

resource "kustomization_resource" "cert_manager" {
  for_each = local.cert_manager_ids_no_ns
  manifest = data.kustomization_build.cert_manager[0].manifests[each.value]

  depends_on = [kubernetes_namespace.cert_manager]
}

resource "time_sleep" "wait_for_cert_manager" {
  count           = var.enable_cert_manager ? 1 : 0
  create_duration = "90s"

  depends_on = [kustomization_resource.cert_manager]
}

data "kustomization_build" "cert_manager_issuer" {
  count = var.enable_cert_manager ? 1 : 0
  path  = local.cert_manager_issuer_url
}

resource "kustomization_resource" "cert_manager_issuer" {
  for_each = var.enable_cert_manager ? data.kustomization_build.cert_manager_issuer[0].ids : toset([])
  manifest = data.kustomization_build.cert_manager_issuer[0].manifests[each.value]

  depends_on = [time_sleep.wait_for_cert_manager]
}
