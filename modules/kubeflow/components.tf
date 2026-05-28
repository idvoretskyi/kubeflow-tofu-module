#######################################
# Central Dashboard
#######################################

data "kustomization_build" "central_dashboard" {
  count = var.enable_central_dashboard ? 1 : 0
  path  = local.central_dashboard_url
}

resource "kustomization_resource" "central_dashboard" {
  for_each = var.enable_central_dashboard ? data.kustomization_build.central_dashboard[0].ids : toset([])
  manifest = data.kustomization_build.central_dashboard[0].manifests[each.value]

  depends_on = [kubernetes_namespace_v1.kubeflow]
}

#######################################
# Profiles & KFAM
#######################################

data "kustomization_build" "profiles_kfam" {
  count = var.enable_profiles ? 1 : 0
  path  = local.profiles_kfam_url
}

resource "kustomization_resource" "profiles_kfam" {
  for_each = var.enable_profiles ? data.kustomization_build.profiles_kfam[0].ids : toset([])
  manifest = data.kustomization_build.profiles_kfam[0].manifests[each.value]

  depends_on = [kubernetes_namespace_v1.kubeflow]
}

#######################################
# Admission Webhook
#######################################

data "kustomization_build" "admission_webhook" {
  count = var.enable_admission_webhook ? 1 : 0
  path  = local.admission_webhook_url
}

resource "kustomization_resource" "admission_webhook" {
  for_each = var.enable_admission_webhook ? data.kustomization_build.admission_webhook[0].ids : toset([])
  manifest = data.kustomization_build.admission_webhook[0].manifests[each.value]

  depends_on = [
    kubernetes_namespace_v1.kubeflow,
    kustomization_resource.cert_manager_issuer,
  ]
}

#######################################
# Notebooks (Controller + Jupyter Web App)
#######################################

data "kustomization_build" "notebook_controller" {
  count = var.enable_notebooks ? 1 : 0
  path  = local.notebook_controller_url
}

resource "kustomization_resource" "notebook_controller" {
  for_each = var.enable_notebooks ? data.kustomization_build.notebook_controller[0].ids : toset([])
  manifest = data.kustomization_build.notebook_controller[0].manifests[each.value]

  depends_on = [kubernetes_namespace_v1.kubeflow]
}

data "kustomization_build" "jupyter_web_app" {
  count = var.enable_notebooks ? 1 : 0
  path  = local.jupyter_web_app_url
}

resource "kustomization_resource" "jupyter_web_app" {
  for_each = var.enable_notebooks ? data.kustomization_build.jupyter_web_app[0].ids : toset([])
  manifest = data.kustomization_build.jupyter_web_app[0].manifests[each.value]

  depends_on = [kubernetes_namespace_v1.kubeflow]
}

#######################################
# Katib
#######################################

data "kustomization_build" "katib" {
  count = var.enable_katib ? 1 : 0
  path  = local.katib_url
}

resource "kustomization_resource" "katib" {
  for_each = var.enable_katib ? data.kustomization_build.katib[0].ids : toset([])
  manifest = data.kustomization_build.katib[0].manifests[each.value]

  depends_on = [kubernetes_namespace_v1.kubeflow]
}

#######################################
# Training Operator
#######################################

data "kustomization_build" "training_operator" {
  count = var.enable_training_operator ? 1 : 0
  path  = local.training_operator_url
}

resource "kustomization_resource" "training_operator" {
  for_each = var.enable_training_operator ? data.kustomization_build.training_operator[0].ids : toset([])
  manifest = data.kustomization_build.training_operator[0].manifests[each.value]

  depends_on = [kubernetes_namespace_v1.kubeflow]
}

# On managed Kubernetes (LKE, GKE, EKS, AKS) the control plane cannot reach
# in-cluster ClusterIPs, so the training-operator ValidatingWebhookConfiguration
# times out whenever a TrainingJob resource (PyTorchJob, TFJob, etc.) is created.
# When training_operator_webhook_failure_policy = "Ignore" we patch the webhook
# after install so those timeouts are non-fatal.
resource "null_resource" "training_operator_webhook_failure_policy" {
  count = var.enable_training_operator && var.training_operator_webhook_failure_policy == "Ignore" ? 1 : 0

  triggers = {
    policy     = var.training_operator_webhook_failure_policy
    install_id = jsonencode(sort(keys(kustomization_resource.training_operator)))
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Available \
        deployment/training-operator \
        -n ${var.kubeflow_namespace} --timeout=300s
      WEBHOOK="validator.training-operator.kubeflow.org"
      COUNT=$(kubectl get validatingwebhookconfiguration "$WEBHOOK" \
        -o jsonpath='{range .webhooks[*]}{.name}{"\n"}{end}' | wc -l)
      PATCH=$(python3 -c "
import json, sys
n = int(sys.argv[1])
print(json.dumps([{'op':'replace','path':f'/webhooks/{i}/failurePolicy','value':'Ignore'} for i in range(n)]))
" "$COUNT")
      kubectl patch validatingwebhookconfiguration "$WEBHOOK" \
        --type=json -p="$PATCH"
    EOT
  }

  depends_on = [kustomization_resource.training_operator]
}

#######################################
# KServe
#######################################

data "kustomization_build" "kserve" {
  count = var.enable_kserve ? 1 : 0
  path  = local.kserve_url
}

resource "kustomization_resource" "kserve" {
  for_each = var.enable_kserve ? data.kustomization_build.kserve[0].ids : toset([])
  manifest = data.kustomization_build.kserve[0].manifests[each.value]

  depends_on = [kubernetes_namespace_v1.kubeflow]
}

data "kustomization_build" "models_web_app" {
  count = var.enable_kserve ? 1 : 0
  path  = local.models_web_app_url
}

resource "kustomization_resource" "models_web_app" {
  for_each = var.enable_kserve ? data.kustomization_build.models_web_app[0].ids : toset([])
  manifest = data.kustomization_build.models_web_app[0].manifests[each.value]

  depends_on = [kustomization_resource.kserve]
}
