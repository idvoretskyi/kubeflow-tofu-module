data "kustomization_build" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  path  = local.cert_manager_url
}

resource "kustomization_resource" "cert_manager" {
  for_each = local.cert_manager_ids_no_ns
  manifest = data.kustomization_build.cert_manager[0].manifests[each.value]

  depends_on = [kubernetes_namespace_v1.cert_manager]
}

# Wait for the cert-manager webhook Deployment to report Available before
# proceeding. A fixed sleep alone is unreliable: on slow nodes the webhook
# process may not be ready within the allotted time, while on fast nodes the
# sleep wastes minutes unnecessarily.
resource "null_resource" "wait_for_cert_manager_webhook" {
  count = var.enable_cert_manager ? 1 : 0

  # Re-run if the set of cert-manager resources changes (e.g. version bump).
  triggers = {
    cert_manager_ids = jsonencode(sort(keys(kustomization_resource.cert_manager)))
  }

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=300s"
  }

  depends_on = [kustomization_resource.cert_manager]
}

# Optional: patch webhook failurePolicy to Ignore for managed Kubernetes
# clusters (LKE, GKE, EKS, AKS) where the managed control plane cannot reach
# in-cluster ClusterIP / pod CIDRs, causing webhook calls to time out.
# Only runs when cert_manager_webhook_failure_policy = "Ignore".
resource "null_resource" "cert_manager_webhook_failure_policy" {
  count = var.enable_cert_manager && var.cert_manager_webhook_failure_policy == "Ignore" ? 1 : 0

  triggers = {
    policy = var.cert_manager_webhook_failure_policy
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl patch validatingwebhookconfiguration cert-manager-webhook \
        --type=json \
        -p='[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Ignore"}]'
      kubectl patch mutatingwebhookconfiguration cert-manager-webhook \
        --type=json \
        -p='[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Ignore"}]'
    EOT
  }

  depends_on = [null_resource.wait_for_cert_manager_webhook]
}

resource "time_sleep" "wait_for_cert_manager" {
  count           = var.enable_cert_manager ? 1 : 0
  create_duration = "${var.cert_manager_wait_seconds}s"

  depends_on = [
    null_resource.wait_for_cert_manager_webhook,
    null_resource.cert_manager_webhook_failure_policy,
  ]
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
