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
    time_sleep.wait_for_cert_manager,
  ]
}

# Step 1b: Cache-deployer RBAC (not included in upstream cluster-scoped-resources)
resource "kubernetes_service_account" "cache_deployer" {
  count = var.enable_pipelines ? 1 : 0

  metadata {
    name      = "kubeflow-pipelines-cache-deployer-sa"
    namespace = var.kubeflow_namespace
  }

  depends_on = [kubernetes_namespace_v1.kubeflow]
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
    kubernetes_namespace_v1.kubeflow,
    kustomization_resource.pipelines_cluster_scoped,
    kubernetes_cluster_role_binding.cache_deployer,
    kustomization_resource.cert_manager_issuer,
    time_sleep.wait_for_cert_manager,
  ]
}
