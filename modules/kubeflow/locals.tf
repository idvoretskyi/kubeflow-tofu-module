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
