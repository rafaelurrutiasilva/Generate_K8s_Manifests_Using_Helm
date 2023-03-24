#!/bin/bash
#
# Bash script to generate Kubernetes manifests using Helm.
#
# ---------------------------------------------------------
#

# Source initial variables.
. ./manifests.ini

# Create root-dir if it missing.
[ -d "$MANIFEST_DIR_NAME" ] || mkdir -p $MANIFEST_DIR_NAME

# Helm workload
helm repo add $HELM_REPO_NAME $HELM_REPO_URL
helm repo update
helm template $HELM_APP_NAME $HELM_REPO_NAME/$HELM_CHART_NAME --namespace $HELM_APP_NAMESPACE --create-namespace --output-dir $MANIFEST_DIR_NAME --include-crds --values $VALUEFILE --debug

gen_sealed_secret(){
	cat manifests/argo-cd/templates/argocd-secret.yaml | kubeseal --format yaml --cert $SEALED_SECRETS_URL > manifests/argo-cd/templates/sealed-argocd-secret.yaml
	if [[ $FIRSTTIMEDEPLOY -eq 1 ]];then
	rm manifests/argo-cd/templates/argocd-secret.yaml
}
