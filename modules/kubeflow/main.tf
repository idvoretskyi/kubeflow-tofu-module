#######################################
# Locals
#######################################

locals {
  manifests_repo = "github.com/kubeflow/manifests"
  manifests_ref  = var.kubeflow_version == "latest" ? "master" : "v${var.kubeflow_version}-branch"

  base_url = "https://${local.manifests_repo}"
  ref      = "?ref=${local.manifests_ref}"

  # Infrastructure URLs
  cert_manager_url        = "${local.base_url}/common/cert-manager/base${local.ref}"
  cert_manager_issuer_url = "${local.base_url}/common/cert-manager/kubeflow-issuer/base${local.ref}"

  istio_crds_url      = "${local.base_url}/common/istio/istio-crds/base${local.ref}"
  istio_namespace_url = "${local.base_url}/common/istio/istio-namespace/base${local.ref}"
  istio_install_url   = "${local.base_url}/common/istio/istio-install/overlays/oauth2-proxy${local.ref}"
  istio_resources_url = "${local.base_url}/common/istio/kubeflow-istio-resources/base${local.ref}"
  oauth2_proxy_url    = "${local.base_url}/common/oauth2-proxy/overlays/m2m-dex-only${local.ref}"
  dex_url             = "${local.base_url}/common/dex/overlays/oauth2-proxy${local.ref}"

  # Kubeflow Pipelines URLs (v1.11+ requires separate cluster-scoped resources)
  pipelines_cluster_scoped_url = "${local.base_url}/applications/pipeline/upstream/env/cert-manager/cluster-scoped-resources${local.ref}"
  pipelines_url = var.enable_istio ? (
    "${local.base_url}/applications/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user${local.ref}"
    ) : (
    "${local.base_url}/applications/pipeline/upstream/env/platform-agnostic${local.ref}"
  )

  central_dashboard_url   = "${local.base_url}/applications/centraldashboard/upstream/overlays/istio${local.ref}"
  admission_webhook_url   = "${local.base_url}/applications/admission-webhook/upstream/overlays/cert-manager${local.ref}"
  profiles_kfam_url       = "${local.base_url}/applications/profiles/upstream/overlays/kubeflow${local.ref}"
  notebook_controller_url = "${local.base_url}/applications/jupyter/notebook-controller/upstream/overlays/kubeflow${local.ref}"
  jupyter_web_app_url     = "${local.base_url}/applications/jupyter/jupyter-web-app/upstream/overlays/istio${local.ref}"
  katib_url               = "${local.base_url}/applications/katib/upstream/installs/katib-with-kubeflow${local.ref}"
  training_operator_url   = "${local.base_url}/applications/training-operator/upstream/overlays/kubeflow${local.ref}"
  kserve_url              = "${local.base_url}/applications/kserve/kserve${local.ref}"
  models_web_app_url      = "${local.base_url}/applications/kserve/models-web-app/overlays/kubeflow${local.ref}"

  # Filter out Namespace resources from cert-manager (we create namespaces ourselves)
  cert_manager_ids = var.enable_cert_manager ? data.kustomization_build.cert_manager[0].ids : toset([])
  cert_manager_ids_no_ns = toset([
    for id in local.cert_manager_ids : id
    if regex("(?P<group_kind>.*/.*)/.*/.*", id)["group_kind"] != "_/Namespace"
  ])
}

#######################################
# Namespaces
#######################################

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

#######################################
# Cert-Manager
#######################################

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

#######################################
# Istio
#######################################

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
    kustomization_resource.cert_manager
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
    kubernetes_namespace.kubeflow
  ]
}

resource "time_sleep" "wait_for_istio" {
  count           = var.enable_istio ? 1 : 0
  create_duration = "120s"

  depends_on = [kustomization_resource.istio]
}

#######################################
# Authentication (OAuth2-Proxy & Dex)
#######################################

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
    time_sleep.wait_for_istio
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
    kustomization_resource.oauth2_proxy
  ]
}

#######################################
# Kubeflow Pipelines
#######################################

# Step 1: Cluster-scoped resources (Argo CRDs, RBAC)
data "kustomization_build" "pipelines_cluster_scoped" {
  count = var.enable_pipelines ? 1 : 0
  path  = local.pipelines_cluster_scoped_url
}

resource "kustomization_resource" "pipelines_cluster_scoped" {
  for_each = var.enable_pipelines ? data.kustomization_build.pipelines_cluster_scoped[0].ids : toset([])
  manifest = data.kustomization_build.pipelines_cluster_scoped[0].manifests[each.value]

  depends_on = [
    kustomization_resource.cert_manager_issuer,
    time_sleep.wait_for_cert_manager
  ]
}

# Step 1b: Cache-deployer RBAC (not included in upstream cluster-scoped-resources)
resource "kubernetes_service_account" "cache_deployer" {
  count = var.enable_pipelines ? 1 : 0

  metadata {
    name      = "kubeflow-pipelines-cache-deployer-sa"
    namespace = var.kubeflow_namespace
  }

  depends_on = [kubernetes_namespace.kubeflow]
}

resource "kubernetes_cluster_role" "cache_deployer" {
  count = var.enable_pipelines ? 1 : 0

  metadata {
    name = "kubeflow-pipelines-cache-deployer-clusterrole"
    labels = {
      "application-crd-id" = "kubeflow-pipelines"
    }
  }

  rule {
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests", "certificatesigningrequests/approval"]
    verbs      = ["create", "delete", "get", "update"]
  }

  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations"]
    verbs      = ["create", "delete", "get", "list", "patch"]
  }

  rule {
    api_groups     = ["certificates.k8s.io"]
    resources      = ["signers"]
    resource_names = ["kubernetes.io/*"]
    verbs          = ["approve"]
  }
}

resource "kubernetes_cluster_role_binding" "cache_deployer" {
  count = var.enable_pipelines ? 1 : 0

  metadata {
    name = "kubeflow-pipelines-cache-deployer-clusterrolebinding"
    labels = {
      "application-crd-id" = "kubeflow-pipelines"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kubeflow-pipelines-cache-deployer-clusterrole"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kubeflow-pipelines-cache-deployer-sa"
    namespace = var.kubeflow_namespace
  }

  depends_on = [kubernetes_cluster_role.cache_deployer]
}

# Step 2: Pipeline namespace-scoped resources
data "kustomization_build" "pipelines" {
  count = var.enable_pipelines ? 1 : 0
  path  = local.pipelines_url
}

resource "kustomization_resource" "pipelines" {
  for_each = var.enable_pipelines ? data.kustomization_build.pipelines[0].ids : toset([])
  manifest = data.kustomization_build.pipelines[0].manifests[each.value]

  depends_on = [
    kubernetes_namespace.kubeflow,
    kustomization_resource.pipelines_cluster_scoped,
    kubernetes_cluster_role_binding.cache_deployer,
    kustomization_resource.cert_manager_issuer,
    time_sleep.wait_for_cert_manager
  ]
}

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

  depends_on = [kubernetes_namespace.kubeflow]
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

  depends_on = [kubernetes_namespace.kubeflow]
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
    kubernetes_namespace.kubeflow,
    kustomization_resource.cert_manager_issuer
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

  depends_on = [kubernetes_namespace.kubeflow]
}

data "kustomization_build" "jupyter_web_app" {
  count = var.enable_notebooks ? 1 : 0
  path  = local.jupyter_web_app_url
}

resource "kustomization_resource" "jupyter_web_app" {
  for_each = var.enable_notebooks ? data.kustomization_build.jupyter_web_app[0].ids : toset([])
  manifest = data.kustomization_build.jupyter_web_app[0].manifests[each.value]

  depends_on = [kubernetes_namespace.kubeflow]
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

  depends_on = [kubernetes_namespace.kubeflow]
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

  depends_on = [kubernetes_namespace.kubeflow]
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

  depends_on = [kubernetes_namespace.kubeflow]
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
